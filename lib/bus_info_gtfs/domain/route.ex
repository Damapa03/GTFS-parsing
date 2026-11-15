defmodule BusInfoGtfs.Domain.Route do
  @moduledoc "A GTFS route (`routes.txt`)."

  @enforce_keys [:route_id, :route_long_name]
  defstruct [:route_id, :route_long_name]

  @type t :: %__MODULE__{
          route_id: integer(),
          route_long_name: String.t()
        }
end
