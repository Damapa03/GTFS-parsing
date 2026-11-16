defmodule BusInfoGtfs.Parser do
  @moduledoc """
  Parses a directory of GTFS `.txt` files into `BusInfoGtfs.Gtfs` structs.

  The parser recognizes:

    * `routes.txt`
    * `trips.txt`
    * `shapes.txt`
    * `stop_times.txt`
    * `stops.txt`

  Any other file is ignored. Missing known files are logged and treated as
  empty tables. Rows that cannot be cast to the expected types are skipped and
  logged; the returned tables only contain valid records.

  The `frequency` of a trip is derived from its `trip_id`: the text before the
  first `_`, without the `OIN` prefix, must start with `F`, `L` or `S`.

  GTFS defines `route_id`, `shape_id` and `stop_id` as strings, but this feed
  uses numeric identifiers, so they are cast to integers. Rows with a
  non-numeric identifier are skipped like any other invalid row.

  This module performs no persistence: `BusInfoGtfs.Ingest` writes the
  result through a `BusInfoGtfs.Storage` implementation.
  """

  require Logger

  alias BusInfoGtfs.Gtfs.{Route, Shape, ShapePoint, Stop, StopTime, Trip}

  @type tables :: %{
          routes: [Route.t()],
          shapes: [Shape.t()],
          trips: [Trip.t()],
          stops: [Stop.t()],
          stop_times: [StopTime.t()]
        }

  # File basename (without extension) => table name.
  @files [
    {"routes", :routes},
    {"trips", :trips},
    {"shapes", :shapes},
    {"stop_times", :stop_times},
    {"stops", :stops}
  ]

  # Table name => [{source column, struct key, caster}].
  @columns %{
    routes: [
      {"route_id", :route_id, :integer},
      {"route_long_name", :route_long_name, :string}
    ],
    trips: [
      {"route_id", :route_id, :integer},
      {"trip_id", :trip_id, :string},
      {"shape_id", :shape_id, :optional_integer},
      {"direction_id", :direction_id, :direction}
    ],
    shapes: [
      {"shape_id", :shape_id, :integer},
      {"shape_pt_lat", :shape_lat, :float},
      {"shape_pt_lon", :shape_lon, :float},
      {"shape_pt_sequence", :shape_pt_sequence, :integer}
    ],
    stop_times: [
      {"trip_id", :trip_id, :string},
      {"arrival_time", :arrival_time, :time},
      {"stop_id", :stop_id, :integer},
      {"stop_sequence", :stop_sequence, :integer}
    ],
    stops: [
      {"stop_id", :stop_id, :integer},
      {"stop_name", :stop_name, :string},
      {"stop_lat", :stop_lat, :float},
      {"stop_lon", :stop_lon, :float}
    ]
  }

  @time_format ~r/^(\d{1,3}):(\d{2}):(\d{2})$/
  @frequencies ~w(F L S)

  @doc """
  Parses every recognized GTFS file in `path`.

  Returns `{:ok, tables}` or `{:error, reason}` when the directory cannot be
  listed.
  """
  @spec parse_directory(Path.t()) :: {:ok, tables()} | {:error, File.posix()}
  def parse_directory(path) do
    case File.ls(path) do
      {:ok, _entries} ->
        rows =
          Map.new(@files, fn {basename, table} ->
            {table, parse_known_file(path, basename, table)}
          end)

        {:ok, to_models(rows)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_known_file(directory, basename, table) do
    source = Path.join(directory, basename <> ".txt")

    if File.regular?(source) do
      parse_table(source, table)
    else
      Logger.warning("GTFS file not found, skipping", file: source)
      []
    end
  end

  defp parse_table(source, table) do
    columns = Map.fetch!(@columns, table)

    [header | rows] =
      source
      |> File.read!()
      |> NimbleCSV.RFC4180.parse_string(trim_bom: true, skip_headers: false)

    indexes =
      header
      |> Enum.map(&String.trim/1)
      |> Enum.with_index()
      |> Map.new()

    validate_columns!(source, columns, indexes)

    rows
    |> Enum.with_index(2)
    |> Enum.reduce([], fn {row, line}, acc ->
      case cast_row(row, columns, indexes, table) do
        {:ok, record} ->
          [record | acc]

        :error ->
          Logger.warning("Skipping invalid GTFS row",
            file: source,
            line: line,
            row: row
          )

          acc
      end
    end)
    |> Enum.reverse()
  end

  defp validate_columns!(source, columns, indexes) do
    case Enum.reject(columns, fn {column, _key, _caster} -> Map.has_key?(indexes, column) end) do
      [] ->
        :ok

      missing ->
        raise ArgumentError,
              "#{source} is missing required column(s): " <>
                Enum.map_join(missing, ", ", &elem(&1, 0))
    end
  end

  defp cast_row(row, columns, indexes, table) do
    with {:ok, attrs} <- cast_columns(row, columns, indexes),
         {:ok, attrs} <- put_derived_fields(table, attrs) do
      {:ok, attrs}
    end
  end

  defp cast_columns(row, columns, indexes) do
    Enum.reduce_while(columns, {:ok, %{}}, fn {column, key, type}, {:ok, acc} ->
      case cast(Enum.at(row, Map.fetch!(indexes, column)), type) do
        {:ok, value} -> {:cont, {:ok, Map.put(acc, key, value)}}
        :error -> {:halt, :error}
      end
    end)
  end

  defp put_derived_fields(:trips, %{trip_id: trip_id} = attrs) do
    with [prefix | _] <- String.split(trip_id, "_", parts: 2),
         "OIN" <> rest <- prefix,
         <<frequency::binary-size(1), _::binary>> <- rest,
         true <- frequency in @frequencies do
      {:ok, Map.put(attrs, :frequency, frequency)}
    else
      _ -> :error
    end
  end

  defp put_derived_fields(_table, attrs), do: {:ok, attrs}

  defp to_models(rows) do
    %{
      routes: Enum.map(rows.routes, &struct(Route, &1)),
      shapes: build_shapes(rows.shapes),
      trips: Enum.map(rows.trips, &struct(Trip, &1)),
      stops: Enum.map(rows.stops, &struct(Stop, &1)),
      stop_times: Enum.map(rows.stop_times, &struct(StopTime, &1))
    }
  end

  defp build_shapes(rows) do
    rows
    |> Enum.group_by(& &1.shape_id)
    |> Enum.sort_by(fn {shape_id, _points} -> shape_id end)
    |> Enum.map(fn {shape_id, points} ->
      points =
        points
        |> Enum.sort_by(& &1.shape_pt_sequence)
        |> Enum.map(
          &struct(
            ShapePoint,
            Map.take(&1, [:shape_id, :shape_pt_sequence, :shape_lat, :shape_lon])
          )
        )

      %Shape{shape_id: shape_id, points: points}
    end)
  end

  defp cast(nil, _type), do: :error

  defp cast(value, :string) do
    case String.trim(value) do
      "" -> :error
      trimmed -> {:ok, trimmed}
    end
  end

  defp cast(value, :integer) do
    case Integer.parse(String.trim(value)) do
      {integer, ""} -> {:ok, integer}
      _ -> :error
    end
  end

  defp cast(value, :optional_integer) do
    if String.trim(value) == "" do
      {:ok, nil}
    else
      cast(value, :integer)
    end
  end

  defp cast(value, :float) do
    case Float.parse(String.trim(value)) do
      {float, ""} -> {:ok, float}
      _ -> :error
    end
  end

  defp cast(value, :direction) do
    case String.trim(value) do
      "0" -> {:ok, false}
      "1" -> {:ok, true}
      _ -> :error
    end
  end

  defp cast(value, :time) do
    case Regex.run(@time_format, String.trim(value)) do
      [_, hours, minutes, seconds] ->
        {:ok,
         String.to_integer(hours) * 3600 + String.to_integer(minutes) * 60 +
           String.to_integer(seconds)}

      _ ->
        :error
    end
  end
end
