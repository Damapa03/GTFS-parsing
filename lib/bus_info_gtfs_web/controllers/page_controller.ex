defmodule BusInfoGtfsWeb.PageController do
  use BusInfoGtfsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
