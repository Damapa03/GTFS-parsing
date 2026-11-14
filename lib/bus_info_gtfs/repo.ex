defmodule BusInfoGtfs.Repo do
  use Ecto.Repo,
    otp_app: :bus_info_gtfs,
    adapter: Ecto.Adapters.SQLite3
end
