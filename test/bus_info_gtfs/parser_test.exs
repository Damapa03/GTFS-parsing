defmodule BusInfoGtfs.ParserTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias BusInfoGtfs.Domain.{Route, Shape, ShapePoint, Stop, StopTime, Trip}

  @fixtures Path.expand("../fixtures/gtfs", __DIR__)

  defp parse_with_log(directory) do
    log =
      capture_log(fn ->
        send(self(), {:tables, BusInfoGtfs.Parser.parse_directory(directory)})
      end)

    assert_received {:tables, result}
    {result, log}
  end

  test "parses every known file into domain structs" do
    {result, _log} = parse_with_log(@fixtures)
    assert {:ok, tables} = result

    assert Map.keys(tables) |> Enum.sort() == [:routes, :shapes, :stop_times, :stops, :trips]
    assert length(tables.routes) == 2
    assert length(tables.trips) == 3
    assert length(tables.shapes) == 2
    assert length(tables.stop_times) == 3
    assert length(tables.stops) == 3
  end

  test "casts routes and stops" do
    assert {:ok, tables} = BusInfoGtfs.Parser.parse_directory(@fixtures)

    assert tables.routes == [
             %Route{route_id: 1, route_long_name: "ZIRKULARRA/CIRCULAR"},
             %Route{route_id: 2, route_long_name: "ERREKATXO/EL REGATO - LASESARRE"}
           ]

    assert tables.stops == [
             %Stop{
               stop_id: 100,
               stop_name: "Polideportivo Lasesarre",
               stop_lat: 43.3020520379822,
               stop_lon: -2.99096700198891
             },
             %Stop{
               stop_id: 200,
               stop_name: "Bagatza 3",
               stop_lat: 43.301035041349,
               stop_lon: -2.9938549962222
             },
             %Stop{
               stop_id: 400,
               stop_name: "Midnight",
               stop_lat: 43.29,
               stop_lon: -2.97
             }
           ]
  end

  test "maps direction_id to booleans and derives the frequency from trip_id" do
    {result, log} = parse_with_log(@fixtures)

    assert {:ok, tables} = result

    assert tables.trips == [
             %Trip{
               trip_id: "OINFL1_010101_1",
               route_id: 1,
               shape_id: 10,
               direction_id: false,
               frequency: "F"
             },
             %Trip{
               trip_id: "OINLL1_010101_2",
               route_id: 1,
               shape_id: 10,
               direction_id: true,
               frequency: "L"
             },
             %Trip{
               trip_id: "OINSL1_010101_3",
               route_id: 1,
               shape_id: 10,
               direction_id: false,
               frequency: "S"
             }
           ]

    assert log =~ "Skipping invalid GTFS row"
  end

  test "skips trips whose id does not contain a valid frequency" do
    directory =
      Path.join(System.tmp_dir!(), "gtfs_frequency_#{System.unique_integer([:positive])}")

    File.mkdir_p!(directory)

    File.write!(
      Path.join(directory, "trips.txt"),
      """
      route_id,service_id,trip_id,trip_headsign,direction_id,block_id,shape_id
      1,S1,OINFL1_010101_1,Valid,0,1,10
      1,S1,T2,No OIN prefix,0,1,10
      1,S1,OINXL1_010101_3,Bad frequency,0,1,10
      """
    )

    on_exit(fn -> File.rm_rf!(directory) end)

    {result, log} = parse_with_log(directory)

    assert {:ok, tables} = result
    assert [%Trip{trip_id: "OINFL1_010101_1", frequency: "F"}] = tables.trips
    assert log =~ "Skipping invalid GTFS row"
  end

  test "casts arrival_time to seconds since midnight, including times over 24h" do
    {result, log} = parse_with_log(@fixtures)

    assert {:ok, tables} = result

    assert tables.stop_times == [
             %StopTime{
               trip_id: "OINFL1_010101_1",
               stop_id: 100,
               stop_sequence: 1,
               arrival_time: 24_000
             },
             %StopTime{
               trip_id: "OINFL1_010101_1",
               stop_id: 200,
               stop_sequence: 2,
               arrival_time: 25_530
             },
             %StopTime{
               trip_id: "OINFL1_010101_1",
               stop_id: 400,
               stop_sequence: 4,
               arrival_time: 90_600
             }
           ]

    assert log =~ "Skipping invalid GTFS row"
    assert StopTime.format_seconds(90_600) == "25:10:00"
  end

  test "groups shape points by shape_id in sequence order" do
    assert {:ok, tables} = BusInfoGtfs.Parser.parse_directory(@fixtures)

    assert tables.shapes == [
             %Shape{
               shape_id: 10,
               points: [
                 %ShapePoint{
                   shape_pt_sequence: 1,
                   shape_lat: 43.3012097735352,
                   shape_lon: -2.98199621781057
                 },
                 %ShapePoint{
                   shape_pt_sequence: 2,
                   shape_lat: 43.3012911196583,
                   shape_lon: -2.98204311099738
                 }
               ]
             },
             %Shape{
               shape_id: 20,
               points: [
                 %ShapePoint{
                   shape_pt_sequence: 1,
                   shape_lat: 43.3020520379822,
                   shape_lon: -2.99096700198891
                 }
               ]
             }
           ]
  end

  test "skips invalid rows" do
    {result, log} = parse_with_log(@fixtures)

    assert {:ok, tables} = result
    assert log =~ "Skipping invalid GTFS row"

    refute Enum.any?(tables.trips, &(&1.trip_id == "OINFL1_010101_4"))
    refute Enum.any?(tables.stop_times, &(&1.stop_sequence == 3))
    refute Enum.any?(tables.stops, &(&1.stop_id == :bad))
  end

  test "treats missing known files as empty tables" do
    directory = Path.join(System.tmp_dir!(), "gtfs_partial_#{System.unique_integer([:positive])}")
    File.mkdir_p!(directory)
    File.cp!(Path.join(@fixtures, "routes.txt"), Path.join(directory, "routes.txt"))

    on_exit(fn -> File.rm_rf!(directory) end)

    {result, log} = parse_with_log(directory)

    assert {:ok, tables} = result
    assert log =~ "GTFS file not found, skipping"
    assert length(tables.routes) == 2
    assert tables.trips == []
    assert tables.shapes == []
    assert tables.stop_times == []
    assert tables.stops == []
  end

  test "returns an error for an unknown directory" do
    assert BusInfoGtfs.Parser.parse_directory("/definitely/not/a/real/directory") ==
             {:error, :enoent}
  end
end
