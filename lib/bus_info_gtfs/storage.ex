defmodule BusInfoGtfs.Storage do
  @moduledoc """
  Persistence contract used by the application services.

  Implementations receive an opaque `state` (an Ecto repo, a fake state in
  tests, ...), which makes the core independent from the concrete database.

  A `storage` value is the tuple `{implementation_module, state}`.
  """

  alias BusInfoGtfs.Domain.{Route, Shape, Stop, StopTime, StopVisit, Trip}

  @type state :: term()

  @type storage :: {module(), state()}

  @type tables :: %{
          routes: [Route.t()],
          shapes: [Shape.t()],
          trips: [Trip.t()],
          stops: [Stop.t()],
          stop_times: [StopTime.t()]
        }

  @doc "Replaces the whole dataset with `tables`, usually in one transaction."
  @callback replace_all(state(), tables()) :: {:ok, state()} | {:error, term()}

  @doc "Returns every route ordered by `route_id`."
  @callback routes(state()) :: [Route.t()]

  @doc "Returns the first trip of a route (source order)."
  @callback first_trip(state(), route_id :: integer()) ::
              {:ok, Trip.t()} | {:error, :no_trip}

  @doc "Returns the stops of a trip ordered by `stop_sequence`."
  @callback stops_for_trip(state(), trip_id :: String.t()) :: [StopVisit.t()]

  @spec replace_all(storage(), tables()) :: {:ok, storage()} | {:error, term()}
  def replace_all({module, state}, tables) do
    with {:ok, state} <- module.replace_all(state, tables) do
      {:ok, {module, state}}
    end
  end

  @spec routes(storage()) :: [Route.t()]
  def routes({module, state}), do: module.routes(state)

  @spec first_trip(storage(), integer()) :: {:ok, Trip.t()} | {:error, :no_trip}
  def first_trip({module, state}, route_id), do: module.first_trip(state, route_id)

  @spec stops_for_trip(storage(), String.t()) :: [StopVisit.t()]
  def stops_for_trip({module, state}, trip_id), do: module.stops_for_trip(state, trip_id)
end
