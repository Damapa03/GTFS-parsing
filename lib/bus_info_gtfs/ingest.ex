defmodule BusInfoGtfs.Ingest do
  @moduledoc """
  Ingests a GTFS directory into a `BusInfoGtfs.Storage` implementation.

  Parsing and persistence are separate steps: this module only coordinates
  them, so the same code can write through any `BusInfoGtfs.Storage`
  implementation, such as the Ecto-backed SQLite storage.
  """

  alias BusInfoGtfs.{Parser, Storage}

  @doc """
  Parses `source_dir` and replaces the whole dataset in `storage`.

  Returns `{:ok, storage, counts}` or `{:error, reason}`.
  """
  @spec ingest(Path.t(), Storage.storage()) ::
          {:ok, Storage.storage(), %{atom() => non_neg_integer()}} | {:error, term()}
  def ingest(source_dir, storage) do
    with {:ok, tables} <- Parser.parse_directory(source_dir),
         {:ok, storage} <- Storage.replace_all(storage, tables) do
      counts = Map.new(tables, fn {table, rows} -> {table, length(rows)} end)
      {:ok, storage, counts}
    end
  end
end
