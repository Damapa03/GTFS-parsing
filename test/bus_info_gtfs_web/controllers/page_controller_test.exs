defmodule BusInfoGtfsWeb.PageControllerTest do
  use BusInfoGtfsWeb.ConnCase

  setup do
    BusInfoGtfs.TestSupport.seed_gtfs!()
    :ok
  end

  @tag capture_log: true
  test "GET / lists the bus routes", %{conn: conn} do
    document =
      conn
      |> get(~p"/")
      |> html_response(200)
      |> LazyHTML.from_fragment()

    assert LazyHTML.text(document) =~ "Bilbao Bus"

    assert length(LazyHTML.to_tree(LazyHTML.query(document, "#routes li"))) == 2
    assert LazyHTML.text(document) =~ "ZIRKULARRA/CIRCULAR"
    assert LazyHTML.text(document) =~ "ERREKATXO/EL REGATO - LASESARRE"

    assert LazyHTML.to_tree(LazyHTML.query_by_id(document, "route-1")) != []
    assert LazyHTML.to_tree(LazyHTML.query(document, "#route-1 .hero-chevron-right")) != []
    assert LazyHTML.to_tree(LazyHTML.query(document, "#route-1 a[href='/routes/1']")) != []
    assert LazyHTML.to_tree(LazyHTML.query(document, "#route-2 a[href='/routes/2']")) != []
  end
end
