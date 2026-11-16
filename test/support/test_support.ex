defmodule BusInfoGtfs.TestSupport do
  @moduledoc "Helpers shared by the tests that touch the database."

  @doc "Creates a unique temporary directory that is removed after the test."
  def tmp_dir(prefix) do
    directory =
      Path.join(System.tmp_dir!(), "#{prefix}_#{System.unique_integer([:positive])}")

    File.mkdir_p!(directory)
    ExUnit.Callbacks.on_exit(fn -> File.rm_rf!(directory) end)
    directory
  end

  @doc """
  Ingests a GTFS directory into the application repo, raising on failure.

  Defaults to the configured `:gtfs_dir`. Call it from a test's `setup` block
  so the sandbox owner has checked out the connection first.
  """
  def seed_gtfs!(directory \\ nil) do
    directory = directory || Application.get_env(:bus_info_gtfs, :gtfs_dir)

    case BusInfoGtfs.Ingest.ingest(
           directory,
           {BusInfoGtfs.Storage.Ecto, BusInfoGtfs.Repo}
         ) do
      {:ok, _storage, _counts} -> :ok
      {:error, reason} -> raise "could not ingest #{directory}: #{inspect(reason)}"
    end
  end

  @doc "Runs `sql` against the application repo and returns the raw rows."
  def query!(sql, params \\ []) do
    %{rows: rows} = BusInfoGtfs.Repo.query!(sql, params)
    rows
  end

  @doc "Returns the first column of the first row, raising when there is none."
  def scalar!(sql, params \\ []) do
    [[value] | _] = query!(sql, params)
    value
  end
end
