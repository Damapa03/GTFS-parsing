defmodule BusInfoGtfs.Gtfs.StopVisit do
  @moduledoc """
  A stop of a trip: joins a `Stop` with its `StopTime`.

  It is a read model used by the explorer service; the storage layer decides how
  to build it (Ecto join, preloaded association, etc.).
  """

  alias BusInfoGtfs.Gtfs.{Stop, StopTime}

  @enforce_keys [:stop, :stop_time]
  defstruct [:stop, :stop_time]

  @type t :: %__MODULE__{
          stop: Stop.t(),
          stop_time: StopTime.t()
        }
end
