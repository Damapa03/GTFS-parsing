defmodule BusInfoGtfs.Domain.Stop do
  @moduledoc "A GTFS stop (`stops.txt`)."

  @enforce_keys [:stop_id, :stop_name, :stop_lat, :stop_lon]
  defstruct [:stop_id, :stop_name, :stop_lat, :stop_lon]

  @type t :: %__MODULE__{
          stop_id: integer(),
          stop_name: String.t(),
          stop_lat: float(),
          stop_lon: float()
        }
end
