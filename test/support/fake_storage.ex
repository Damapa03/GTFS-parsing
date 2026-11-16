defmodule BusInfoGtfs.FakeStorage do
  @moduledoc """
  In-memory `BusInfoGtfs.Storage` implementation for tests.

  It stores the tables as they are and builds `StopVisit` read models on
  demand.
  """

  @behaviour BusInfoGtfs.Storage

  alias BusInfoGtfs.Gtfs.StopVisit

  defstruct routes: [],
            shapes: [],
            trips: [],
            stops: [],
            stop_times: [],
            replace_calls: 0

  def new(attrs \\ []), do: struct!(__MODULE__, attrs)

  @impl true
  def replace_all(state, tables) do
    {:ok,
     %{
       state
       | routes: tables.routes,
         shapes: tables.shapes,
         trips: tables.trips,
         stops: tables.stops,
         stop_times: tables.stop_times,
         replace_calls: state.replace_calls + 1
     }}
  end

  @impl true
  def routes(state), do: Enum.sort_by(state.routes, & &1.route_id)

  @impl true
  def route(state, route_id) do
    case Enum.find(state.routes, &(&1.route_id == route_id)) do
      nil -> {:error, :not_found}
      route -> {:ok, route}
    end
  end

  @impl true
  def trips(state, route_id), do: Enum.filter(state.trips, &(&1.route_id == route_id))

  @impl true
  def first_trip(state, route_id) do
    case Enum.find(state.trips, &(&1.route_id == route_id)) do
      nil -> {:error, :no_trip}
      trip -> {:ok, trip}
    end
  end

  @impl true
  def stops_for_trip(state, trip_id) do
    stops_by_id = Map.new(state.stops, &{&1.stop_id, &1})

    state.stop_times
    |> Enum.filter(&(&1.trip_id == trip_id))
    |> Enum.sort_by(& &1.stop_sequence)
    |> Enum.map(fn stop_time ->
      %StopVisit{stop: Map.fetch!(stops_by_id, stop_time.stop_id), stop_time: stop_time}
    end)
  end

  @impl true
  def stop_visits_for_trips(state, trip_ids) do
    trip_ids = MapSet.new(trip_ids)
    stops_by_id = Map.new(state.stops, &{&1.stop_id, &1})

    state.stop_times
    |> Enum.filter(&MapSet.member?(trip_ids, &1.trip_id))
    |> Enum.sort_by(&{&1.trip_id, &1.stop_sequence})
    |> Enum.map(fn stop_time ->
      %StopVisit{stop: Map.fetch!(stops_by_id, stop_time.stop_id), stop_time: stop_time}
    end)
  end
end
