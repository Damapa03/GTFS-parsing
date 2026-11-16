defmodule BusInfoGtfs.Storage.Ecto do
  @moduledoc """
  Ecto/SQLite implementation of the `BusInfoGtfs.Storage` contract.

  The `state` is the repo module, so the storage tuple is typically
  `{BusInfoGtfs.Storage.Ecto, BusInfoGtfs.Repo}`.

  `replace_all/2` runs in a single transaction: the dataset is deleted in
  foreign-key-safe order and inserted again in chunks. If any insert fails, the
  transaction (including the deletes) is rolled back and the previous dataset is
  kept.
  """

  @behaviour BusInfoGtfs.Storage

  import Ecto.Query

  alias BusInfoGtfs.Gtfs.{Route, Shape, ShapePoint, Stop, StopTime, StopVisit, Trip}

  # Keeps each INSERT well below SQLite's bound-parameter limit.
  @chunk_size 500

  @impl true
  def replace_all(repo, tables) do
    repo.transaction(fn -> do_replace_all(repo, tables) end)
  rescue
    error -> {:error, error}
  end

  @impl true
  def routes(repo) do
    repo.all(from route in Route, order_by: [asc: route.route_id])
  end

  @impl true
  def route(repo, route_id) do
    case repo.get(Route, route_id) do
      nil -> {:error, :not_found}
      route -> {:ok, route}
    end
  end

  @impl true
  def trips(repo, route_id) do
    repo.all(
      from trip in Trip,
        where: trip.route_id == ^route_id,
        order_by: [asc: trip.trip_id]
    )
  end

  @impl true
  def first_trip(repo, route_id) do
    case repo.one(
           from trip in Trip,
             where: trip.route_id == ^route_id,
             order_by: [asc: trip.trip_id],
             limit: 1
         ) do
      nil -> {:error, :no_trip}
      trip -> {:ok, trip}
    end
  end

  @impl true
  def stops_for_trip(repo, trip_id) do
    from(stop_time in StopTime,
      join: stop in assoc(stop_time, :stop),
      where: stop_time.trip_id == ^trip_id,
      order_by: [asc: stop_time.stop_sequence],
      select: {stop, stop_time}
    )
    |> repo.all()
    |> Enum.map(fn {stop, stop_time} -> %StopVisit{stop: stop, stop_time: stop_time} end)
  end

  @impl true
  def stop_visits_for_trips(_repo, []), do: []

  def stop_visits_for_trips(repo, trip_ids) do
    from(stop_time in StopTime,
      join: stop in assoc(stop_time, :stop),
      where: stop_time.trip_id in ^trip_ids,
      order_by: [asc: stop_time.trip_id, asc: stop_time.stop_sequence],
      select: {stop, stop_time}
    )
    |> repo.all()
    |> Enum.map(fn {stop, stop_time} -> %StopVisit{stop: stop, stop_time: stop_time} end)
  end

  defp do_replace_all(repo, tables) do
    delete_all(repo)

    insert_all(repo, Route, tables.routes)
    insert_all(repo, Shape, tables.shapes)
    insert_all(repo, Stop, tables.stops)
    insert_all(repo, ShapePoint, shape_points(tables.shapes))
    insert_all(repo, Trip, tables.trips)
    insert_all(repo, StopTime, tables.stop_times)

    repo
  end

  # stop_times → trips → shape_points → shapes → stops → routes.
  defp delete_all(repo) do
    repo.delete_all(StopTime)
    repo.delete_all(Trip)
    repo.delete_all(ShapePoint)
    repo.delete_all(Shape)
    repo.delete_all(Stop)
    repo.delete_all(Route)
  end

  defp insert_all(_repo, _schema, []), do: :ok

  defp insert_all(repo, schema, records) do
    fields = schema.__schema__(:fields)

    records
    |> Enum.map(&Map.take(&1, fields))
    |> Enum.chunk_every(@chunk_size)
    |> Enum.each(&repo.insert_all(schema, &1))
  end

  defp shape_points(shapes) do
    Enum.flat_map(shapes, fn
      %Shape{points: points} when is_list(points) -> points
      _shape -> []
    end)
  end
end
