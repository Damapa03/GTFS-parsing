defmodule BusInfoGtfs.Domain.ShapePoint do
  @moduledoc "A single point of a GTFS shape (`shapes.txt`)."

  @enforce_keys [:shape_pt_sequence, :shape_lat, :shape_lon]
  defstruct [:shape_pt_sequence, :shape_lat, :shape_lon]

  @type t :: %__MODULE__{
          shape_pt_sequence: integer(),
          shape_lat: float(),
          shape_lon: float()
        }
end
