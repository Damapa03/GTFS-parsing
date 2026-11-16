defmodule BusInfoGtfs.Services.ExploreRouteTest do
  use ExUnit.Case, async: true

  alias BusInfoGtfs.{FakeStorage, Parser, Storage}
  alias BusInfoGtfs.Gtfs.{Stop, StopSchedule, StopTime, Trip}
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

  describe "schedule_for_route/4" do
    test "groups every trip of the day and direction by stop" do
      storage = storage!(@web_fixtures)

      assert [
               %StopSchedule{
                 stop: %{stop_id: 100},
                 times: [
                   %StopTime{arrival_time: 24_000, trip_id: "OINLL1_010101_1"},
                   %StopTime{arrival_time: 25_200, trip_id: "OINLL1_010101_2"}
                 ]
               },
               %StopSchedule{
                 stop: %{stop_id: 200},
                 times: [%StopTime{arrival_time: 25_830, trip_id: "OINLL1_010101_2"}]
               },
               %StopSchedule{
                 stop: %{stop_id: 300},
                 times: [%StopTime{arrival_time: 26_400, trip_id: "OINLL1_010101_2"}]
               }
             ] = ExploreRoute.schedule_for_route(storage, 1, :weekday, false)
    end

    test "ignores trips from other days and directions" do
      storage = storage!(@web_fixtures)

      assert [
               %StopSchedule{
                 stop: %{stop_id: 300},
                 times: [%StopTime{arrival_time: 27_000, trip_id: "OINLL2_010201_2"}]
               },
               %StopSchedule{
                 stop: %{stop_id: 200},
                 times: [%StopTime{arrival_time: 27_900, trip_id: "OINLL2_010201_2"}]
               },
               %StopSchedule{
                 stop: %{stop_id: 100},
                 times: [%StopTime{arrival_time: 28_800, trip_id: "OINLL2_010201_2"}]
               }
             ] = ExploreRoute.schedule_for_route(storage, 2, :weekday, true)
    end

    test "includes single-stop trips", %{storage: storage} do
      assert [
               %StopSchedule{
                 stop: %Stop{stop_name: "Depot"},
                 times: [%StopTime{arrival_time: 24_000, trip_id: "OINFL1_010101_1"}]
               }
             ] = ExploreRoute.schedule_for_route(storage, 1, :holiday, false)
    end

    test "returns an empty schedule when no trip matches", %{storage: storage} do
      assert [] = ExploreRoute.schedule_for_route(storage, 1, :weekday, false)
    end

    test "keeps every visit when a trip repeats a stop" do
      storage =
        {FakeStorage,
         FakeStorage.new(
           trips: [
             %Trip{trip_id: "loop", route_id: 1, frequency: "L", direction_id: false}
           ],
           stops: [
             %Stop{stop_id: 1, stop_name: "Start"},
             %Stop{stop_id: 2, stop_name: "Middle"}
           ],
           stop_times: [
             %StopTime{trip_id: "loop", stop_id: 1, stop_sequence: 1, arrival_time: 100},
             %StopTime{trip_id: "loop", stop_id: 2, stop_sequence: 2, arrival_time: 200},
             %StopTime{trip_id: "loop", stop_id: 1, stop_sequence: 3, arrival_time: 300}
           ]
         )}

      assert [
               %StopSchedule{
                 stop: %{stop_id: 1},
                 times: [
                   %StopTime{arrival_time: 100},
                   %StopTime{arrival_time: 300}
                 ]
               },
               %StopSchedule{
                 stop: %{stop_id: 2},
                 times: [%StopTime{arrival_time: 200}]
               }
             ] = ExploreRoute.schedule_for_route(storage, 1, :weekday, false)
    end

    test "appends stops that only appear on other trips" do
      storage =
        {FakeStorage,
         FakeStorage.new(
           trips: [
             %Trip{trip_id: "a", route_id: 1, frequency: "L", direction_id: false},
             %Trip{trip_id: "b", route_id: 1, frequency: "L", direction_id: false}
           ],
           stops: [
             %Stop{stop_id: 1, stop_name: "One"},
             %Stop{stop_id: 2, stop_name: "Two"},
             %Stop{stop_id: 3, stop_name: "Three"}
           ],
           stop_times: [
             %StopTime{trip_id: "a", stop_id: 1, stop_sequence: 1, arrival_time: 100},
             %StopTime{trip_id: "a", stop_id: 2, stop_sequence: 2, arrival_time: 200},
             %StopTime{trip_id: "b", stop_id: 3, stop_sequence: 1, arrival_time: 300}
           ]
         )}

      assert [
               %StopSchedule{stop: %{stop_id: 1}},
               %StopSchedule{stop: %{stop_id: 2}},
               %StopSchedule{stop: %{stop_id: 3}}
             ] = ExploreRoute.schedule_for_route(storage, 1, :weekday, false)
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
