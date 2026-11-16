defmodule BusInfoGtfsWeb.RouteLive do
  use BusInfoGtfsWeb, :live_view

  alias BusInfoGtfs.Catalog
  alias BusInfoGtfs.Services.ExploreRoute

  @days [
    weekday: "Weekdays",
    saturday: "Saturday",
    holiday: "Public holidays"
  ]

  @default_day :weekday
  @day_keys %{"weekday" => :weekday, "saturday" => :saturday, "holiday" => :holiday}

  @impl true
  def mount(%{"route_id" => route_id}, _session, socket) do
    with {:ok, id} <- parse_route_id(route_id),
         {:ok, route} <- Catalog.get_route(id) do
      {from, to} = split_name(route.route_long_name)

      {:ok,
       socket
       |> assign(:route, route)
       |> assign(:route_from, from)
       |> assign(:route_to, to)
       |> assign(:day, @default_day)
       |> assign(:direction, false)
       |> assign(:selected_stop_ids, [])
       |> assign(:days, @days)
       |> assign(:page_title, route.route_long_name)}
    else
      _error ->
        {:ok,
         socket
         |> put_flash(:error, "Route not found.")
         |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply,
     socket
     |> assign(:selected_stop_ids, [])
     |> assign(:day, parse_day(params["day"]))
     |> assign_schedule()}
  end

  @impl true
  def handle_event("select_stop", %{"stop_id" => stop_id}, socket) do
    schedule = socket.assigns.schedule

    case Enum.find_index(schedule, &(to_string(&1.stop.stop_id) == stop_id)) do
      nil ->
        {:noreply, socket}

      index ->
        selected_stop = Enum.at(schedule, index)

        selected_stop_ids =
          if List.first(socket.assigns.selected_stop_ids) == selected_stop.stop.stop_id do
            []
          else
            [selected_stop | ExploreRoute.next_stops(schedule, index)]
            |> Enum.map(& &1.stop.stop_id)
          end

        {:noreply, assign(socket, :selected_stop_ids, selected_stop_ids)}
    end
  end

  def handle_event("swap_direction", _params, %{assigns: %{route: %{route_id: 1}}} = socket) do
    {:noreply, socket}
  end

  def handle_event("swap_direction", _params, socket) do
    %{route_from: route_from, route_to: route_to, direction: direction} = socket.assigns

    {:noreply,
     socket
     |> assign(:route_from, route_to)
     |> assign(:route_to, route_from)
     |> assign(:direction, not direction)
     |> assign(:selected_stop_ids, [])
     |> assign(:page_title, "#{route_to} - #{route_from}")
     |> assign_schedule()}
  end

  defp assign_schedule(socket) do
    %{route: route, day: day, direction: direction} = socket.assigns
    assign(socket, :schedule, Catalog.schedule_for_route(route.route_id, day, direction))
  end

  defp parse_route_id(route_id) do
    case Integer.parse(route_id) do
      {id, ""} -> {:ok, id}
      _ -> :error
    end
  end

  defp parse_day(day), do: Map.get(@day_keys, day, @default_day)

  defp split_name(name) do
    case String.split(name, " - ", parts: 2) do
      [from, to] -> {from, to}
      [single] -> {single, nil}
    end
  end

  defp format_time(seconds) do
    hours = div(seconds, 3600)
    minutes = seconds |> rem(3600) |> div(60)

    "#{pad(hours)}:#{pad(minutes)}"
  end

  defp pad(number), do: number |> Integer.to_string() |> String.pad_leading(2, "0")

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <Layouts.app_header />

      <main class="mx-auto w-full max-w-2xl flex-1 px-4 py-6 sm:px-6 sm:py-8">
        <div class="flex items-center gap-2">
          <.link
            id="back-link"
            navigate={~p"/"}
            aria-label="Back to all routes"
            class="flex size-9 shrink-0 items-center justify-center rounded-full text-neutral-600 transition hover:bg-neutral-100 hover:text-neutral-900 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600"
          >
            <.icon name="hero-arrow-left" class="size-5" />
          </.link>

          <h2
            id="route-name"
            class="flex min-w-0 flex-1 items-center gap-1.5 text-lg font-semibold tracking-tight sm:text-xl"
          >
            <span id="route-from" class="truncate">{@route_from}</span>
            <.icon
              :if={@route_to}
              name="hero-arrow-right"
              class="size-4 shrink-0 text-neutral-400"
            />
            <span :if={@route_to} id="route-to" class="truncate">{@route_to}</span>
          </h2>

          <button
            :if={@route.route_id != 1 and @route_to}
            type="button"
            id="swap-direction"
            phx-click="swap_direction"
            aria-label="Swap route direction"
            title="Swap route direction"
            class="flex size-9 shrink-0 items-center justify-center rounded-full text-neutral-600 transition hover:bg-neutral-100 hover:text-neutral-900 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600"
          >
            <.icon name="hero-arrows-right-left" class="size-5" />
          </button>
        </div>

        <section aria-label="Stops along the route" class="mt-8">
          <div class="-mx-4 overflow-x-auto px-4 pb-2 sm:-mx-6 sm:px-6">
            <div class="relative w-max">
              <span
                class="pointer-events-none absolute left-12 right-12 top-5 h-px bg-neutral-300"
                aria-hidden="true"
              />
              <ol id="stop-timeline" class="relative flex items-start">
                <li
                  :for={entry <- @schedule}
                  id={"timeline-stop-#{entry.stop.stop_id}"}
                  class="relative flex w-24 shrink-0 flex-col items-center"
                >
                  <button
                    type="button"
                    phx-click="select_stop"
                    phx-value-stop_id={entry.stop.stop_id}
                    aria-label={"Highlight #{entry.stop.stop_name} and the following stops"}
                    aria-pressed={to_string(entry.stop.stop_id in @selected_stop_ids)}
                    class={[
                      "group flex w-full flex-col items-center rounded-lg px-1 pb-1 text-center transition focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600",
                      entry.stop.stop_id in @selected_stop_ids && "bg-red-50"
                    ]}
                  >
                    <span class="relative flex h-10 w-full items-center justify-center">
                      <span
                        class="absolute inset-y-0 left-1/2 w-px -translate-x-1/2 bg-neutral-300"
                        aria-hidden="true"
                      />
                      <span class={[
                        "relative size-3 rounded-full border-2 border-red-600 bg-white transition",
                        entry.stop.stop_id in @selected_stop_ids &&
                          "scale-125 bg-red-600 ring-4 ring-red-100"
                      ]} />
                    </span>

                    <span
                      class={[
                        "mt-1 w-full truncate px-1 text-[11px] leading-4",
                        entry.stop.stop_id in @selected_stop_ids &&
                          "font-semibold text-red-700",
                        entry.stop.stop_id not in @selected_stop_ids && "text-neutral-500"
                      ]}
                      title={entry.stop.stop_name}
                    >
                      {entry.stop.stop_name}
                    </span>
                  </button>
                </li>
              </ol>
            </div>
          </div>

          <p :if={@schedule == []} class="py-6 text-center text-sm text-neutral-500">
            No stops available for this route.
          </p>
        </section>

        <nav
          id="day-selector"
          aria-label="Service day"
          class="mt-6 grid grid-cols-3 gap-1 rounded-xl bg-neutral-100 p-1"
        >
          <.link
            :for={{key, label} <- @days}
            id={"day-#{key}"}
            patch={~p"/routes/#{@route.route_id}?day=#{key}"}
            class={[
              "rounded-lg px-2 py-2 text-center text-xs font-semibold transition sm:text-sm",
              if(@day == key,
                do: "bg-red-600 text-white shadow-sm",
                else: "text-neutral-600 hover:bg-white hover:text-neutral-900"
              )
            ]}
          >
            {label}
          </.link>
        </nav>

        <section aria-label="Stop timetable" class="mt-6">
          <div
            id="stop-schedule-scroll"
            role="region"
            aria-label="Stop timetable, scroll horizontally to see all times"
            tabindex="0"
            class="overflow-x-auto overscroll-x-contain rounded-2xl border border-neutral-200 bg-white focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600"
          >
            <ol id="stop-schedule" class="w-max min-w-full divide-y divide-neutral-200">
              <li
                :for={entry <- @schedule}
                id={"stop-time-#{entry.stop.stop_id}"}
                class={[
                  "flex w-max min-w-full items-center gap-3 p-3",
                  entry.stop.stop_id in @selected_stop_ids && "bg-red-50"
                ]}
              >
                <span class="stop-name sticky left-0 z-10 flex w-48 shrink-0 items-center rounded-lg bg-red-600 px-3 py-2 text-sm font-semibold text-white">
                  {entry.stop.stop_name}
                </span>

                <ul class="flex shrink-0 items-center gap-1.5">
                  <li :for={stop_time <- entry.times} class="shrink-0">
                    <time class="rounded-md bg-neutral-100 px-2 py-1 text-xs font-semibold tabular-nums text-neutral-700">
                      {format_time(stop_time.arrival_time)}
                    </time>
                  </li>
                </ul>
              </li>
              <li
                :if={@schedule == []}
                class="w-full bg-white px-4 py-10 text-center text-sm text-neutral-500"
              >
                No schedule available for this day.
              </li>
            </ol>
          </div>
        </section>
      </main>
    </Layouts.app>
    """
  end
end
