defmodule BusInfoGtfs.Gtfs.Shape do
  @moduledoc "A GTFS shape (`shapes.txt`) with its ordered points."

  use Ecto.Schema

  alias BusInfoGtfs.Gtfs.ShapePoint

  @primary_key {:shape_id, :id, autogenerate: false}

  schema "shapes" do
    has_many :points, ShapePoint, foreign_key: :shape_id
    has_many :trips, BusInfoGtfs.Gtfs.Trip, foreign_key: :shape_id
  end

  @type t :: %__MODULE__{
          shape_id: integer() | nil,
          points: [ShapePoint.t()] | Ecto.Association.NotLoaded.t()
        }
end
