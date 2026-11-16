defmodule BusInfoGtfs.Services.ExploreRoute do
  @moduledoc """
  Use cases for exploring a route.

  The service depends on the `BusInfoGtfs.Storage` contract, not on a
  concrete database, so an Ecto-backed storage can be plugged in without
  changing the use cases.
  """

  alias BusInfoGtfs.Gtfs.{Route, StopSchedule, StopVisit, Trip}
  alias BusInfoGtfs.Storage

  @type day :: :weekday | :saturday | :holiday

  # GTFS frequency code derived from the trip id, see `BusInfoGtfs.Gtfs.Trip`.
  @day_frequencies %{weekday: "L", saturday: "S", holiday: "F"}

  @doc "Lists all routes ordered by `route_id`."
  @spec routes(Storage.storage()) :: [Route.t()]
  def routes(storage), do: Storage.routes(storage)

  @doc "Returns the route with `route_id`."
  @spec route(Storage.storage(), integer()) :: {:ok, Route.t()} | {:error, :not_found}
  def route(storage, route_id), do: Storage.route(storage, route_id)

  @doc "Returns the GTFS frequency code for a service day."
  @spec frequency_for_day(day()) :: Trip.frequency()
  def frequency_for_day(day), do: Map.fetch!(@day_frequencies, day)

  @doc """
  Returns the timetable of a route for a service day and direction.

  Every trip matching the service frequency and direction is included. Arrival
  times are grouped by stop and sorted chronologically. Stops follow the order
  of the most complete trip; stops that only appear on other trips are
  appended. A stop visited more than once by a trip (for example on a circular
  route) keeps every visit.
  """
  @spec schedule_for_route(Storage.storage(), integer(), day(), boolean()) :: [StopSchedule.t()]
  def schedule_for_route(storage, route_id, day, direction) do
    frequency = frequency_for_day(day)

    trips =
      storage
      |> Storage.trips(route_id)
      |> Enum.filter(&(&1.frequency == frequency and &1.direction_id == direction))

    storage
    |> Storage.stop_visits_for_trips(Enum.map(trips, & &1.trip_id))
    |> build_schedule()
  end

  @doc "Returns the first trip of a route (source order)."
  @spec first_trip(Storage.storage(), integer()) ::
          {:ok, Trip.t()} | {:error, :no_trip}
  def first_trip(storage, route_id), do: Storage.first_trip(storage, route_id)

  @doc "Returns the stops of a trip ordered by `stop_sequence`."
  @spec stops_for_trip(Storage.storage(), Trip.t()) :: [StopVisit.t()]
  def stops_for_trip(storage, %Trip{trip_id: trip_id}) do
    Storage.stops_for_trip(storage, trip_id)
  end

  @doc """
  Returns up to `count` stops that come after the stop at zero-based `index`.
  """
  @spec next_stops([term()], non_neg_integer(), non_neg_integer()) :: [term()]
  def next_stops(stops, index, count \\ 3) do
    stops
    |> Enum.drop(index + 1)
    |> Enum.take(count)
  end

  defp build_schedule([]), do: []

  defp build_schedule(visits) do
    reference =
      visits
      |> Enum.group_by(& &1.stop_time.trip_id)
      |> Enum.max_by(fn {trip_id, trip_visits} -> {length(trip_visits), trip_id} end)
      |> elem(1)

    ordered_stop_ids =
      reference
      |> Enum.map(& &1.stop.stop_id)
      |> Enum.uniq()

    extra_stop_ids =
      visits
      |> Enum.reject(&(&1.stop.stop_id in ordered_stop_ids))
      |> Enum.sort_by(&{&1.stop_time.trip_id, &1.stop_time.stop_sequence})
      |> Enum.map(& &1.stop.stop_id)
      |> Enum.uniq()

    visits_by_stop = Enum.group_by(visits, & &1.stop.stop_id)

    (ordered_stop_ids ++ extra_stop_ids)
    |> Enum.map(fn stop_id ->
      stop_visits = Map.fetch!(visits_by_stop, stop_id)

      %StopSchedule{
        stop: hd(stop_visits).stop,
        times:
          stop_visits
          |> Enum.map(& &1.stop_time)
          |> Enum.sort_by(&{&1.arrival_time, &1.trip_id})
      }
    end)
  end
end
