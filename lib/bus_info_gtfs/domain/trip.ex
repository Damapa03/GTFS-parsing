defmodule BusInfoGtfs.Domain.Trip do
  @moduledoc """
  A GTFS trip (`trips.txt`).

  `frequency` is derived from the `trip_id` during parsing. It is one of `"F"`,
  `"L"` or `"S"` and identifies the service frequency of the trip.
  """

  @enforce_keys [:trip_id, :route_id, :direction_id, :frequency]
  defstruct [:trip_id, :route_id, :shape_id, :direction_id, :frequency]

  @type frequency :: String.t()

  @type t :: %__MODULE__{
          trip_id: String.t(),
          route_id: integer(),
          shape_id: integer() | nil,
          direction_id: boolean(),
          frequency: frequency()
        }
end
