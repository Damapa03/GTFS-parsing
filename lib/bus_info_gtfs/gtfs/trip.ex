defmodule BusInfoGtfs.Gtfs.Trip do
  @moduledoc """
  A GTFS trip (`trips.txt`).

  `frequency` is derived from the `trip_id` during parsing. It is one of `"F"`,
  `"L"` or `"S"` and identifies the service frequency of the trip.
  """

  use Ecto.Schema

  @primary_key {:trip_id, :string, autogenerate: false}

  schema "trips" do
    belongs_to :route, BusInfoGtfs.Gtfs.Route, references: :route_id
    belongs_to :shape, BusInfoGtfs.Gtfs.Shape, references: :shape_id

    field :direction_id, :boolean
    field :frequency, :string

    has_many :stop_times, BusInfoGtfs.Gtfs.StopTime, foreign_key: :trip_id
  end

  @type frequency :: String.t()

  @type t :: %__MODULE__{
          trip_id: String.t() | nil,
          route_id: integer() | nil,
          shape_id: integer() | nil,
          direction_id: boolean() | nil,
          frequency: frequency() | nil
        }
end
