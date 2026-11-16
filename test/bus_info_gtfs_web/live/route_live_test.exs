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

    test "hides the swap direction button on route 1", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/routes/1")

      refute has_element?(view, "#swap-direction")
    end

    test "swaps route name and timetable direction", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/routes/2")

      assert has_element?(view, "#route-from", "ERREKATXO/EL REGATO")
      assert has_element?(view, "#route-to", "LASESARRE")
      assert has_element?(view, "#stop-time-100 time", "06:30")
      refute has_element?(view, "#stop-time-300 time", "07:30")

      view |> element("#swap-direction") |> render_click()

      assert has_element?(view, "#route-from", "LASESARRE")
      assert has_element?(view, "#route-to", "ERREKATXO/EL REGATO")
      assert has_element?(view, "#stop-time-300 time", "07:30")
      assert has_element?(view, "#stop-time-100 time", "08:00")
      refute has_element?(view, "#stop-time-100 time", "06:30")

      view |> element("#swap-direction") |> render_click()

      assert has_element?(view, "#route-from", "ERREKATXO/EL REGATO")
      assert has_element?(view, "#route-to", "LASESARRE")
      assert has_element?(view, "#stop-time-100 time", "06:30")
      refute has_element?(view, "#stop-time-300 time", "07:30")
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

      assert has_element?(view, "#stop-time-100 time", "06:40")
      assert has_element?(view, "#stop-time-100 time", "07:00")
      assert has_element?(view, "#day-weekday.bg-red-600")

      view |> element("#day-saturday") |> render_click()

      assert_patch(view, ~p"/routes/1?day=saturday")
      assert has_element?(view, "#stop-time-100 time", "08:00")
      refute has_element?(view, "#stop-time-100 time", "06:40")
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

    test "highlights the selected stop and up to three following stops", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/routes/1")

      view |> element("#timeline-stop-100 button") |> render_click()

      assert has_element?(view, "#timeline-stop-100 button[aria-pressed='true'].bg-red-50")
      assert has_element?(view, "#timeline-stop-200 button[aria-pressed='true'].bg-red-50")
      assert has_element?(view, "#timeline-stop-300 button[aria-pressed='true'].bg-red-50")
      assert has_element?(view, "#stop-time-100.bg-red-50")
      assert has_element?(view, "#stop-time-200.bg-red-50")
      assert has_element?(view, "#stop-time-300.bg-red-50")

      view |> element("#timeline-stop-200 button") |> render_click()

      refute has_element?(view, "#timeline-stop-100 button[aria-pressed='true']")
      assert has_element?(view, "#timeline-stop-200 button[aria-pressed='true']")
      assert has_element?(view, "#timeline-stop-300 button[aria-pressed='true']")
      refute has_element?(view, "#stop-time-100.bg-red-50")
      assert has_element?(view, "#stop-time-200.bg-red-50")
      assert has_element?(view, "#stop-time-300.bg-red-50")

      view |> element("#timeline-stop-200 button") |> render_click()

      refute has_element?(view, "#timeline-stop-100 button[aria-pressed='true']")
      refute has_element?(view, "#timeline-stop-200 button[aria-pressed='true']")
      refute has_element?(view, "#timeline-stop-300 button[aria-pressed='true']")
      refute has_element?(view, "#stop-time-100.bg-red-50")
      refute has_element?(view, "#stop-time-200.bg-red-50")
      refute has_element?(view, "#stop-time-300.bg-red-50")

      view |> element("#timeline-stop-300 button") |> render_click()

      assert has_element?(view, "#timeline-stop-300 button[aria-pressed='true']")
      assert has_element?(view, "#stop-time-300.bg-red-50")
      refute has_element?(view, "#stop-time-200.bg-red-50")
    end

    test "lists every trip time for each stop", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/routes/1")

      assert has_element?(view, "#stop-schedule-scroll[role='region'].overflow-x-auto")
      assert has_element?(view, "#stop-schedule")
      assert has_element?(view, "#stop-time-100 .stop-name.sticky.left-0.w-48")
      assert has_element?(view, "#stop-time-100 ul li time", "06:40")
      assert has_element?(view, "#stop-time-100 time", "06:40")
      assert has_element?(view, "#stop-time-100 time", "07:00")
      assert has_element?(view, "#stop-time-200 time", "07:10")
      assert has_element?(view, "#stop-time-300 time", "07:20")
    end

    test "styles the stop names with a red background and white text", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/routes/1")

      assert has_element?(
               view,
               "#stop-time-100 .stop-name.bg-red-600.text-white",
               "Polideportivo Lasesarre"
             )
    end
  end

  test "redirects to the home page for an unknown route", %{conn: conn} do
    assert {:error, {:live_redirect, %{to: "/"}}} = live(conn, ~p"/routes/999")
    assert {:error, {:live_redirect, %{to: "/"}}} = live(conn, ~p"/routes/not-a-number")
  end
end
