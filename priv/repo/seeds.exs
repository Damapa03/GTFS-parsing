# Populates the database with the GTFS feed configured under :gtfs_dir.

alias BusInfoGtfs.{Ingest, Repo}
alias BusInfoGtfs.Storage.Ecto

directory = Application.get_env(:bus_info_gtfs, :gtfs_dir) || "GTFS"

case Ingest.ingest(directory, {Ecto, Repo}) do
  {:ok, _storage, counts} ->
    Mix.shell().info("Ingested #{directory}: #{inspect(counts)}")

  {:error, reason} ->
    Mix.raise("GTFS ingestion failed for #{directory}: #{inspect(reason)}")
end
