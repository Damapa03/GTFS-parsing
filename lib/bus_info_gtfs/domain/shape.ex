defmodule BusInfoGtfs.Domain.Shape do
  @moduledoc "A GTFS shape (`shapes.txt`) with its ordered points."

  alias BusInfoGtfs.Domain.ShapePoint

  @enforce_keys [:shape_id, :points]
  defstruct [:shape_id, :points]

  @type t :: %__MODULE__{
          shape_id: integer(),
          points: [ShapePoint.t()]
        }
end
