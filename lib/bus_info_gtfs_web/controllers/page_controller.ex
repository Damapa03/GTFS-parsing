defmodule BusInfoGtfsWeb.PageController do
  use BusInfoGtfsWeb, :controller

  alias BusInfoGtfs.Catalog

  def home(conn, _params) do
    render(conn, :home, routes: Catalog.list_routes())
  end
end
