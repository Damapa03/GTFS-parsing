defmodule BusInfoGtfs.IngestTest do
  use ExUnit.Case, async: true

  alias BusInfoGtfs.{FakeStorage, Ingest}

  @fixtures Path.expand("../fixtures/gtfs", __DIR__)

  test "parses the directory and replaces the dataset" do
    assert {:ok, {FakeStorage, state}, counts} =
             Ingest.ingest(@fixtures, {FakeStorage, FakeStorage.new()})

    assert counts == %{routes: 2, shapes: 2, stops: 3, stop_times: 3, trips: 3}
    assert state.replace_calls == 1
    assert length(state.routes) == 2
    assert length(state.shapes) == 2
    assert length(state.trips) == 3
    assert length(state.stops) == 3
    assert length(state.stop_times) == 3
  end

  test "returns the file error when the directory does not exist" do
    missing = Path.join(@fixtures, "missing")

    assert {:error, :enoent} = Ingest.ingest(missing, {FakeStorage, FakeStorage.new()})
  end
end
