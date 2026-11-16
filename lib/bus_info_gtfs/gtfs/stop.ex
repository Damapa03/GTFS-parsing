defmodule BusInfoGtfs.Gtfs.Stop do
  @moduledoc "A GTFS stop (`stops.txt`)."

  use Ecto.Schema

  @primary_key {:stop_id, :id, autogenerate: false}

  schema "stops" do
    field :stop_name, :string
    field :stop_lat, :float
    field :stop_lon, :float

    has_many :stop_times, BusInfoGtfs.Gtfs.StopTime, foreign_key: :stop_id
  end

  @type t :: %__MODULE__{
          stop_id: integer() | nil,
          stop_name: String.t() | nil,
          stop_lat: float() | nil,
          stop_lon: float() | nil
        }
end
