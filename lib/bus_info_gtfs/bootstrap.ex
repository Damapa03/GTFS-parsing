defmodule BusInfoGtfs.Bootstrap do
  @moduledoc """
  Optionally ingests the GTFS feed when the database is empty.

  This is meant for development and single-node deployments where running
  `mix gtfs.ingest` is inconvenient. It only runs when `:ingest_on_start` is
  true and the `routes` table has no rows, so a populated database is never
  replaced at boot.
  """

  use GenServer

  require Logger

  alias BusInfoGtfs.{Ingest, Repo}
  alias BusInfoGtfs.Gtfs.Route
  alias BusInfoGtfs.Storage.Ecto

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{}, {:continue, :maybe_ingest}}
  end

  @impl true
  def handle_continue(:maybe_ingest, state) do
    maybe_ingest()
    {:noreply, state}
  end

  defp maybe_ingest do
    if Application.get_env(:bus_info_gtfs, :ingest_on_start, false) do
      ingest_if_empty()
    end
  rescue
    error ->
      Logger.error("GTFS bootstrap failed: " <> Exception.message(error))
  end

  defp ingest_if_empty do
    if Repo.aggregate(Route, :count) == 0 do
      directory = Application.get_env(:bus_info_gtfs, :gtfs_dir) || "GTFS"

      case Ingest.ingest(directory, {Ecto, Repo}) do
        {:ok, _storage, counts} ->
          Logger.info("GTFS bootstrap ingested #{directory}: #{inspect(counts)}")

        {:error, reason} ->
          Logger.error("GTFS bootstrap could not ingest #{directory}: #{inspect(reason)}")
      end
    end
  end
end
