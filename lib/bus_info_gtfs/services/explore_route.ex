defmodule BusInfoGtfs.Services.ExploreRoute do
  @moduledoc """
  Use cases for exploring a route.

  The service depends on the `BusInfoGtfs.Storage` contract, not on a
  concrete database, so an Ecto-backed storage can be plugged in without
  changing the use cases.
  """

  alias BusInfoGtfs.Domain.{Route, StopVisit, Trip}
  alias BusInfoGtfs.Storage

  @type day :: :weekday | :saturday | :holiday

  # GTFS frequency code derived from the trip id, see `BusInfoGtfs.Domain.Trip`.
  @day_frequencies %{weekday: "L", saturday: "S", holiday: "F"}

  @doc "Lists all routes ordered by `route_id`."
  @spec routes(Storage.storage()) :: [Route.t()]
  def routes(storage), do: Storage.routes(storage)

  @doc "Returns the route with `route_id`."
  @spec route(Storage.storage(), integer()) :: {:ok, Route.t()} | {:error, :not_found}
  def route(storage, route_id) do
    case Enum.find(Storage.routes(storage), &(&1.route_id == route_id)) do
      nil -> {:error, :not_found}
      route -> {:ok, route}
    end
  end

  @doc "Returns the GTFS frequency code for a service day."
  @spec frequency_for_day(day()) :: Trip.frequency()
  def frequency_for_day(day), do: Map.fetch!(@day_frequencies, day)

  @doc """
  Returns the stops of a route for the given service day and direction.

  It uses the first trip with more than one stop, which skips incomplete trips
  that some GTFS feeds include. If no trip has more than one stop, the first
  single-stop trip is used.
  """
  @spec stops_for_route(Storage.storage(), integer(), day(), boolean()) :: [StopVisit.t()]
  def stops_for_route(storage, route_id, day, direction) do
    frequency = frequency_for_day(day)

    storage
    |> Storage.trips(route_id)
    |> Enum.filter(&(&1.frequency == frequency and &1.direction_id == direction))
    |> first_complete_stops(storage)
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

  defp first_complete_stops(trips, storage) do
    {complete, single} =
      Enum.reduce_while(trips, {nil, nil}, fn trip, {_complete, single} ->
        case stops_for_trip(storage, trip) do
          [] -> {:cont, {nil, single}}
          [_] = stops -> {:cont, {nil, single || stops}}
          stops -> {:halt, {stops, single}}
        end
      end)

    complete || single || []
  end
end
