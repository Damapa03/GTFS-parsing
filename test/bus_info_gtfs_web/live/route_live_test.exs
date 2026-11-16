defmodule BusInfoGtfsWeb.RouteLiveTest do
  use BusInfoGtfsWeb.ConnCase

  import Phoenix.LiveViewTest

  setup do
    BusInfoGtfs.TestSupport.seed_gtfs!()
    :ok
  end

  describe "route header" do
    test "splits a two part name with a direction arrow", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/routes/2")

      assert has_element?(view, "#route-name #route-from", "ERREKATXO/EL REGATO")
      assert has_element?(view, "#route-name .hero-arrow-right")
      assert has_element?(view, "#route-name #route-to", "LASESARRE")
    end

    test "shows a single part name without an arrow", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/routes/1")

      assert has_element?(view, "#route-name #route-from", "ZIRKULARRA/CIRCULAR")
      refute has_element?(view, "#route-name .hero-arrow-right")
      refute has_element?(view, "#route-name #route-to")
    end

    test "has a back link to the home page", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/routes/1")

      assert has_element?(view, "#back-link[href='/']")
      assert has_element?(view, "#back-link .hero-arrow-left")
    end

    test "shows an inert swap direction button", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/routes/1")

      assert has_element?(view, "#swap-direction[disabled]")
      assert has_element?(view, "#swap-direction .hero-arrows-right-left")
    end
  end

  describe "day selector" do
    test "shows the day buttons in order", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/routes/1")

      assert has_element?(view, "#day-selector a:nth-of-type(1)#day-weekday", "Weekdays")
      assert has_element?(view, "#day-selector a:nth-of-type(2)#day-saturday", "Saturday")

      assert has_element?(
               view,
               "#day-selector a:nth-of-type(3)#day-holiday",
               "Public holidays"
             )
    end

    test "switches the schedule when a day is selected", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/routes/1")

      assert has_element?(view, "#stop-time-100 time", "07:00")
      assert has_element?(view, "#day-weekday.bg-red-600")

      view |> element("#day-saturday") |> render_click()

      assert_patch(view, ~p"/routes/1?day=saturday")
      assert has_element?(view, "#stop-time-100 time", "08:00")
      assert has_element?(view, "#day-saturday.bg-red-600")

      view |> element("#day-holiday") |> render_click()

      assert_patch(view, ~p"/routes/1?day=holiday")
      assert has_element?(view, "#stop-time-100 time", "09:00")
      assert has_element?(view, "#day-holiday.bg-red-600")
    end

    test "reads the day from the query string", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/routes/1?day=saturday")

      assert has_element?(view, "#day-saturday.bg-red-600")
      assert has_element?(view, "#stop-time-100 time", "08:00")
    end

    test "falls back to weekdays for an unknown day", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/routes/1?day=nope")

      assert has_element?(view, "#day-weekday.bg-red-600")
      assert has_element?(view, "#stop-time-100 time", "07:00")
    end
  end

  describe "stops" do
    test "renders a timeline with the stop names", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/routes/1")

      assert has_element?(view, "#stop-timeline")
      assert has_element?(view, "#timeline-stop-100", "Polideportivo Lasesarre")
      assert has_element?(view, "#timeline-stop-200", "Bagatza 3")
      assert has_element?(view, "#timeline-stop-300", "Muelle de La Benedicta")
    end

    test "lists the arrival time before the stop name", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/routes/1")

      assert has_element?(view, "#stop-time-100 time", "07:00")
      assert has_element?(view, "#stop-time-100", "Polideportivo Lasesarre")

      text =
        view
        |> render()
        |> LazyHTML.from_fragment()
        |> LazyHTML.query_by_id("stop-time-100")
        |> LazyHTML.text()

      assert String.starts_with?(String.trim(text), "07:00")
    end

    test "skips single stop trips", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/routes/1")

      refute has_element?(view, "#stop-time-100 time", "06:40")
      assert has_element?(view, "#stop-time-100 time", "07:00")
      assert has_element?(view, "#stop-time-300")
    end
  end

  test "redirects to the home page for an unknown route", %{conn: conn} do
    assert {:error, {:live_redirect, %{to: "/"}}} = live(conn, ~p"/routes/999")
    assert {:error, {:live_redirect, %{to: "/"}}} = live(conn, ~p"/routes/not-a-number")
  end
end
