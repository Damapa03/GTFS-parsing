defmodule BusInfoGtfs.Catalog do
  @moduledoc """
  Read access to the GTFS dataset used by the web layer.

  The Ecto-backed storage is the source of truth: pages read the migrated
  SQLite tables instead of re-parsing the GTFS directory. Populate the database
  with `mix gtfs.ingest` (or `mix setup`).
  """

  alias BusInfoGtfs.{Repo, Services.ExploreRoute}
  alias BusInfoGtfs.Storage.Ecto

  @type day :: ExploreRoute.day()

  @doc "Returns every route ordered by `route_id`."
  @spec list_routes() :: [BusInfoGtfs.Gtfs.Route.t()]
  def list_routes, do: ExploreRoute.routes(storage())

  @doc "Returns the route with `route_id`."
  @spec get_route(integer()) :: {:ok, BusInfoGtfs.Gtfs.Route.t()} | {:error, :not_found}
  def get_route(route_id), do: ExploreRoute.route(storage(), route_id)

  @doc "Returns the stops of a route for a service day and direction."
  @spec stops_for_route(integer(), day(), boolean()) :: [BusInfoGtfs.Gtfs.StopVisit.t()]
  def stops_for_route(route_id, day, direction) do
    ExploreRoute.stops_for_route(storage(), route_id, day, direction)
  end

  defp storage, do: {Ecto, Repo}
end
