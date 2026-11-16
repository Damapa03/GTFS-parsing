defmodule BusInfoGtfs.Gtfs.Route do
  @moduledoc "A GTFS route (`routes.txt`)."

  use Ecto.Schema

  @primary_key {:route_id, :id, autogenerate: false}

  schema "routes" do
    field :route_long_name, :string

    has_many :trips, BusInfoGtfs.Gtfs.Trip, foreign_key: :route_id
  end

  @type t :: %__MODULE__{
          route_id: integer() | nil,
          route_long_name: String.t() | nil
        }
end
