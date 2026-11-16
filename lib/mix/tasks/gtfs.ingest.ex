defmodule Mix.Tasks.Gtfs.Ingest do
  @shortdoc "Ingests a GTFS directory into the database"

  @moduledoc """
  Parses a GTFS directory and replaces the database dataset with it.

      mix gtfs.ingest
      mix gtfs.ingest path/to/gtfs

  The directory defaults to the `:gtfs_dir` application setting, which points
  at `GTFS/` in this repository. Every table is replaced inside one
  transaction, so a failed import keeps the previous dataset.
  """

  use Mix.Task

  alias BusInfoGtfs.{Ingest, Repo}
  alias BusInfoGtfs.Storage.Ecto

  @impl true
  def run(args) do
    # This task does the ingestion itself; avoid racing the startup bootstrap.
    Application.put_env(:bus_info_gtfs, :ingest_on_start, false)

    Mix.Task.run("app.start")

    directory =
      args
      |> List.first()
      |> case do
        nil -> Application.get_env(:bus_info_gtfs, :gtfs_dir) || "GTFS"
        dir -> dir
      end
      |> Path.expand()

    case Ingest.ingest(directory, {Ecto, Repo}) do
      {:ok, _storage, counts} ->
        Mix.shell().info("Ingested #{directory}")
        Mix.shell().info(format_counts(counts))

      {:error, reason} ->
        Mix.raise("GTFS ingestion failed for #{directory}: #{inspect(reason)}")
    end
  end

  defp format_counts(counts) do
    counts
    |> Enum.sort()
    |> Enum.map_join("\n", fn {table, count} -> "  #{table}: #{count}" end)
  end
end
