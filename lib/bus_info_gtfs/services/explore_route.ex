defmodule BusInfoGtfs.Services.ExploreRoute do
  @moduledoc """
  Use cases for exploring a route.

  The service depends on the `BusInfoGtfs.Storage` contract, not on a
  concrete database, so an Ecto-backed storage can be plugged in without
  changing the use cases.
  """

  alias BusInfoGtfs.{Gtfs.Trip, Storage}

  @doc "Lists all routes ordered by `route_id`."
  @spec routes(Storage.storage()) :: [BusInfoGtfs.Gtfs.Route.t()]
  def routes(storage), do: Storage.routes(storage)

  @doc "Returns the first trip of a route (source order)."
  @spec first_trip(Storage.storage(), integer()) ::
          {:ok, Trip.t()} | {:error, :no_trip}
  def first_trip(storage, route_id), do: Storage.first_trip(storage, route_id)

  @doc "Returns the stops of a trip ordered by `stop_sequence`."
  @spec stops_for_trip(Storage.storage(), Trip.t()) :: [BusInfoGtfs.Gtfs.StopVisit.t()]
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
end
