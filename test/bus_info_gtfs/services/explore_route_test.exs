defmodule BusInfoGtfs.Services.ExploreRouteTest do
  use ExUnit.Case, async: true

  alias BusInfoGtfs.{FakeStorage, Parser, Storage}
  alias BusInfoGtfs.Gtfs.Trip
  alias BusInfoGtfs.Services.ExploreRoute

  @fixtures Path.expand("../../fixtures/gtfs_domain", __DIR__)
  @web_fixtures Path.expand("../../fixtures/gtfs_web", __DIR__)

  setup do
    %{storage: storage!(@fixtures)}
  end

  defp storage!(directory) do
    {:ok, tables} = Parser.parse_directory(directory)
    {:ok, storage} = Storage.replace_all({FakeStorage, FakeStorage.new()}, tables)
    storage
  end

  describe "routes" do
    test "lists routes ordered by route_id", %{storage: storage} do
      assert [%{route_id: 1}, %{route_id: 2}] = ExploreRoute.routes(storage)
    end

    test "returns the route or an error", %{storage: storage} do
      assert {:ok, %{route_id: 1, route_long_name: "ZIRKULARRA/CIRCULAR"}} =
               ExploreRoute.route(storage, 1)

      assert {:error, :not_found} = ExploreRoute.route(storage, 99)
    end
  end

  describe "frequency_for_day/1" do
    test "maps each service day to its GTFS frequency code" do
      assert ExploreRoute.frequency_for_day(:weekday) == "L"
      assert ExploreRoute.frequency_for_day(:saturday) == "S"
      assert ExploreRoute.frequency_for_day(:holiday) == "F"
    end
  end

  describe "stops_for_route/4" do
    test "returns the ordered stops of a matching trip", %{storage: storage} do
      assert [
               %{stop: %{stop_name: "First"}, stop_time: %{arrival_time: 25_200}},
               %{stop: %{stop_name: "Second"}},
               %{stop: %{stop_name: "Third"}},
               %{stop: %{stop_name: "Fourth"}},
               %{stop: %{stop_name: "Fifth"}}
             ] = ExploreRoute.stops_for_route(storage, 2, :saturday, false)
    end

    test "falls back to a single-stop trip", %{storage: storage} do
      assert [%{stop: %{stop_name: "Depot"}}] =
               ExploreRoute.stops_for_route(storage, 1, :holiday, false)
    end

    test "returns an empty list when no trip matches", %{storage: storage} do
      assert [] = ExploreRoute.stops_for_route(storage, 1, :weekday, false)
    end

    test "skips single-stop trips when a complete trip exists" do
      storage = storage!(@web_fixtures)

      assert [
               %{stop_time: %{arrival_time: 25_200}},
               %{stop_time: %{arrival_time: 25_830}},
               %{stop_time: %{arrival_time: 26_400}}
             ] = ExploreRoute.stops_for_route(storage, 1, :weekday, false)
    end
  end

  describe "trips" do
    test "first_trip/2 returns the first trip or an error", %{storage: storage} do
      assert {:ok, %Trip{trip_id: "OINFL1_010101_1"}} = ExploreRoute.first_trip(storage, 1)
      assert {:error, :no_trip} = ExploreRoute.first_trip(storage, 99)
    end

    test "stops_for_trip/2 returns the ordered stop visits", %{storage: storage} do
      trip = %Trip{trip_id: "OINSL2_010201_1"}

      assert [%{stop: %{stop_name: "First"}} | _] =
               ExploreRoute.stops_for_trip(storage, trip)

      assert length(ExploreRoute.stops_for_trip(storage, trip)) == 5
    end
  end

  describe "next_stops/3" do
    test "returns the stops after the given index" do
      assert ExploreRoute.next_stops([1, 2, 3, 4, 5], 1) == [3, 4, 5]
      assert ExploreRoute.next_stops([1, 2, 3, 4, 5], 1, 2) == [3, 4]
      assert ExploreRoute.next_stops([1, 2], 1) == []
    end
  end
end
