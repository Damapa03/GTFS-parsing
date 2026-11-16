defmodule BusInfoGtfs.Gtfs.StopTime do
  @moduledoc """
  A GTFS stop time (`stop_times.txt`).

  `arrival_time` is stored as seconds since midnight so GTFS times greater than
  24:00 (e.g. `25:10:00`) keep working.
  """

  use Ecto.Schema

  @primary_key false

  schema "stop_times" do
    belongs_to :trip, BusInfoGtfs.Gtfs.Trip, references: :trip_id, type: :string
    belongs_to :stop, BusInfoGtfs.Gtfs.Stop, references: :stop_id, type: :id

    field :stop_sequence, :integer
    field :arrival_time, :integer
  end

  @type t :: %__MODULE__{
          trip_id: String.t() | nil,
          stop_id: integer() | nil,
          stop_sequence: integer() | nil,
          arrival_time: non_neg_integer() | nil
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
