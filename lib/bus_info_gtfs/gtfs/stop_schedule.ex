defmodule BusInfoGtfs.Gtfs.StopSchedule do
  @moduledoc """
  Timetable entry for a stop: every arrival time of the trips serving it.

  It is a read model built by the explorer service, which groups the stop times
  of all matching trips by stop.
  """

  alias BusInfoGtfs.Gtfs.{Stop, StopTime}

  @enforce_keys [:stop, :times]
  defstruct [:stop, :times]

  @type t :: %__MODULE__{
          stop: Stop.t(),
          times: [StopTime.t()]
        }
end
