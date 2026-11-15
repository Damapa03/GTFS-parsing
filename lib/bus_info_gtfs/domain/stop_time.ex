defmodule BusInfoGtfs.Domain.StopTime do
  @moduledoc """
  A GTFS stop time (`stop_times.txt`).

  `arrival_time` is stored as seconds since midnight so GTFS times greater than
  24:00 (e.g. `25:10:00`) keep working.
  """

  @enforce_keys [:trip_id, :stop_id, :stop_sequence, :arrival_time]
  defstruct [:trip_id, :stop_id, :stop_sequence, :arrival_time]

  @type t :: %__MODULE__{
          trip_id: String.t(),
          stop_id: integer(),
          stop_sequence: integer(),
          arrival_time: non_neg_integer()
        }

  @doc """
  Formats the arrival time as `HH:MM:SS` (hours may have more than two digits).
  """
  @spec format_arrival_time(t()) :: String.t()
  def format_arrival_time(%__MODULE__{arrival_time: seconds}), do: format_seconds(seconds)

  @spec format_seconds(non_neg_integer()) :: String.t()
  def format_seconds(seconds) when is_integer(seconds) and seconds >= 0 do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    seconds = rem(seconds, 60)

    "#{pad(hours)}:#{pad(minutes)}:#{pad(seconds)}"
  end

  defp pad(number), do: number |> Integer.to_string() |> String.pad_leading(2, "0")
end
