# BusInfoGtfs

Phoenix application that shows bus routes, stops and schedules from a GTFS
feed. The feed is parsed once and stored in SQLite through Ecto; the web layer
reads the database instead of re-parsing the GTFS files on every request.

## Requirements

* Elixir 1.17+ and Erlang/OTP
* No separate database server: SQLite is embedded

## Setup

```sh
mix setup
```

`mix setup` fetches dependencies, creates and migrates the database, seeds it
from the GTFS feed, and builds the assets.

If the schema changed or you want a clean database:

```sh
mix ecto.reset
```

Or step by step:

```sh
mix ecto.create
mix ecto.migrate
mix gtfs.ingest
```

Start the server with `mix phx.server` (or `iex -S mix phx.server`) and open
[`localhost:4000`](http://localhost:4000).

## GTFS data

* The feed lives in `GTFS/` at the repository root. Its path is configured as
  `:gtfs_dir` in `config/config.exs`.
* Re-ingest at any time:

  ```sh
  mix gtfs.ingest
  mix gtfs.ingest path/to/another/feed
  ```

  Ingestion replaces every table inside a single transaction, so a failed
  import keeps the previous dataset.
* The development database is `bus_info_gtfs_dev.db`; tests use
  `bus_info_gtfs_test.db`. Both are gitignored.
* `mix ecto.setup` also seeds the feed through `priv/repo/seeds.exs`.
* To ingest automatically when the database has no routes, enable:

  ```elixir
  config :bus_info_gtfs, ingest_on_start: true
  ```

  It is off by default so it never races `mix gtfs.ingest` or the seeds.

## Tests

```sh
mix test
mix precommit
```

The `test` alias creates and migrates the test database first. Test data comes
from small fixtures:

* `test/fixtures/gtfs` — parser edge cases (invalid rows, times after 24:00)
* `test/fixtures/gtfs_domain` — service behaviour (days, directions, ordering)
* `test/fixtures/gtfs_web` — LiveView and controller tests

Web tests seed `gtfs_web` into the database from their `setup` block, inside the
SQL sandbox. Database tests are synchronous (`async: false`) because SQLite
allows a single writer.

## Production

Run the migrations and ingest the feed once per deployment or feed update:

```sh
mix ecto.migrate
mix gtfs.ingest
```

`mix gtfs.ingest` needs the application code and Mix, so run it from a build or
release command rather than from the running release image.

## Data model

* Ecto schemas live under `BusInfoGtfs.Gtfs.*` (routes, shapes, stops, trips,
  stop times). `StopVisit` joins a stop with its stop time and `StopSchedule`
  groups every arrival time of a stop, so the web layer can show all trips of a
  day at once.
* `BusInfoGtfs.Storage` is the persistence contract and
  `BusInfoGtfs.Storage.Ecto` is the SQLite implementation. `BusInfoGtfs.Catalog`
  is the thin read API used by the web layer.
* `route_id`, `shape_id` and `stop_id` are stored as integers because this feed
  uses numeric identifiers; `trip_id` is a string. Supporting alphanumeric GTFS
  IDs would require changing the parser, schemas and migration.
* `arrival_time` is stored as seconds since midnight, so GTFS times greater
  than `24:00:00` keep working.

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
