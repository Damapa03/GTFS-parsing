import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :bus_info_gtfs, BusInfoGtfs.Repo,
  database: Path.expand("../bus_info_gtfs_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

# Use the small web fixtures instead of the real GTFS dataset in tests.
config :bus_info_gtfs, gtfs_dir: Path.expand("../test/fixtures/gtfs_web", __DIR__)

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :bus_info_gtfs, BusInfoGtfsWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "j3ppcewOuoCb4rJ7wCcZcyQlCawZDiIOgbznqH1WvpS5i8htMK5m5KDx/H3O0MVr",
  server: false

# In test we don't send emails
config :bus_info_gtfs, BusInfoGtfs.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true
