defmodule BusInfoGtfs.Catalog do
  @moduledoc """
  Read access to the GTFS dataset used by the web layer.

  The files are parsed once and cached in `:persistent_term`, so pages do not
  re-read the GTFS directory on every request. The dataset is read through the
  `BusInfoGtfs.Storage` contract, which keeps the web layer independent from
  the concrete persistence.
  """

  require Logger

  alias BusInfoGtfs.Ingest
  alias BusInfoGtfs.Services.ExploreRoute
  alias BusInfoGtfs.Storage.InMemory

  @storage_key {__MODULE__, :storage}

  @doc "Returns every route ordered by `route_id`."
  @spec list_routes() :: [BusInfoGtfs.Domain.Route.t()]
  def list_routes, do: ExploreRoute.routes(storage())

  @doc """
  Replaces the cached dataset with the GTFS files in `directory`.

  Defaults to the directory configured under `:gtfs_dir`.
  """
  @spec reload(Path.t() | nil) :: {:ok, %{atom() => non_neg_integer()}} | {:error, term()}
  def reload(directory \\ nil) do
    directory = directory || gtfs_directory()

    with {:ok, storage, counts} <- Ingest.ingest(directory, {InMemory, %InMemory{}}) do
      :persistent_term.put(@storage_key, storage)
      {:ok, counts}
    end
  end

  defp storage do
    case :persistent_term.get(@storage_key, nil) do
      nil -> load()
      storage -> storage
    end
  end

  defp load do
    case reload() do
      {:ok, _counts} ->
        :persistent_term.get(@storage_key)

      {:error, reason} ->
        Logger.error("Could not load the GTFS dataset: #{inspect(reason)}")
        empty_storage()
    end
  rescue
    error ->
      Logger.error("Could not load the GTFS dataset: " <> Exception.message(error))
      empty_storage()
  end

  defp empty_storage, do: {InMemory, %InMemory{}}

  defp gtfs_directory do
    Application.get_env(:bus_info_gtfs, :gtfs_dir, Path.expand("../../GTFS", __DIR__))
  end
end
