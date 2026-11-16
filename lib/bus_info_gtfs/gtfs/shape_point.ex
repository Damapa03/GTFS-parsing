defmodule BusInfoGtfs.Gtfs.ShapePoint do
  @moduledoc "A single point of a GTFS shape (`shapes.txt`)."

  use Ecto.Schema

  @primary_key false

  schema "shape_points" do
    belongs_to :shape, BusInfoGtfs.Gtfs.Shape, references: :shape_id, type: :id

    field :shape_pt_sequence, :integer
    field :shape_lat, :float
    field :shape_lon, :float
  end

  @type t :: %__MODULE__{
          shape_id: integer() | nil,
          shape_pt_sequence: integer() | nil,
          shape_lat: float() | nil,
          shape_lon: float() | nil
        }
end
