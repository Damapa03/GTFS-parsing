defmodule BusInfoGtfs.Storage.EctoTest do
  use BusInfoGtfs.DataCase, async: false

  alias BusInfoGtfs.{Parser, Storage}
  alias BusInfoGtfs.Gtfs.{Route, Shape, ShapePoint, Stop, StopTime, Trip}
  alias BusInfoGtfs.Storage.Ecto

  @fixtures Path.expand("../../fixtures/gtfs", __DIR__)

  setup do
    assert {:ok, tables} = Parser.parse_directory(@fixtures)
    %{tables: tables}
  end

  describe "replace_all/2" do
    test "inserts every parsed table", %{tables: tables} do
      assert {:ok, {Ecto, Repo}} = Storage.replace_all({Ecto, Repo}, tables)

      assert Repo.aggregate(Route, :count) == 2
      assert Repo.aggregate(Trip, :count) == 3
      assert Repo.aggregate(Stop, :count) == 3
      assert Repo.aggregate(StopTime, :count) == 3
      assert Repo.aggregate(Shape, :count) == 2
      assert Repo.aggregate(ShapePoint, :count) == 3
    end

    test "replaces the dataset without duplicating rows", %{tables: tables} do
      assert {:ok, _storage} = Storage.replace_all({Ecto, Repo}, tables)
      assert {:ok, _storage} = Storage.replace_all({Ecto, Repo}, tables)

      assert Repo.aggregate(Route, :count) == 2
      assert Repo.aggregate(StopTime, :count) == 3
    end

    test "keeps the previous dataset when an insert fails", %{tables: tables} do
      assert {:ok, _storage} = Storage.replace_all({Ecto, Repo}, tables)

      duplicate = %{tables | routes: tables.routes ++ [hd(tables.routes)]}

      assert {:error, _reason} = Storage.replace_all({Ecto, Repo}, duplicate)

      assert Repo.aggregate(Route, :count) == 2
      assert Repo.aggregate(StopTime, :count) == 3
    end
  end

  describe "read callbacks" do
    setup %{tables: tables} do
      assert {:ok, storage} = Storage.replace_all({Ecto, Repo}, tables)
      %{storage: storage}
    end

    test "routes/1 returns routes ordered by route_id", %{storage: storage} do
      assert [%Route{route_id: 1}, %Route{route_id: 2}] = Storage.routes(storage)
    end

    test "route/2 returns the route or an error", %{storage: storage} do
      assert {:ok, %Route{route_id: 2, route_long_name: "ERREKATXO/EL REGATO - LASESARRE"}} =
               Storage.route(storage, 2)

      assert {:error, :not_found} = Storage.route(storage, 999)
    end

    test "trips/2 returns the trips of a route ordered by trip_id", %{storage: storage} do
      assert [
               %Trip{trip_id: "OINFL1_010101_1"},
               %Trip{trip_id: "OINLL1_010101_2"},
               %Trip{trip_id: "OINSL1_010101_3"}
             ] = Storage.trips(storage, 1)

      assert [] = Storage.trips(storage, 2)
    end

    test "first_trip/2 returns the first trip or an error", %{storage: storage} do
      assert {:ok, %Trip{trip_id: "OINFL1_010101_1"}} = Storage.first_trip(storage, 1)
      assert {:error, :no_trip} = Storage.first_trip(storage, 2)
    end

    test "stops_for_trip/2 builds ordered stop visits", %{storage: storage} do
      assert [
               %BusInfoGtfs.Gtfs.StopVisit{
                 stop: %Stop{stop_id: 100, stop_name: "Polideportivo Lasesarre"},
                 stop_time: %StopTime{stop_sequence: 1, arrival_time: 24_000}
               },
               %BusInfoGtfs.Gtfs.StopVisit{
                 stop: %Stop{stop_id: 200},
                 stop_time: %StopTime{stop_sequence: 2, arrival_time: 25_530}
               },
               %BusInfoGtfs.Gtfs.StopVisit{
                 stop: %Stop{stop_id: 400},
                 stop_time: %StopTime{stop_sequence: 4, arrival_time: 90_600}
               }
             ] = Storage.stops_for_trip(storage, "OINFL1_010101_1")

      assert [] = Storage.stops_for_trip(storage, "unknown")
    end
  end
end
