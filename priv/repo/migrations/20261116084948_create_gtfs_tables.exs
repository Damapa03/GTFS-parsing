defmodule BusInfoGtfs.Repo.Migrations.CreateGtfsTables do
  use Ecto.Migration

  def change do
    create table(:routes, primary_key: false, options: "STRICT") do
      add :route_id, :integer, primary_key: true
      add :route_long_name, :string, null: false
    end

    create table(:shapes, primary_key: false, options: "STRICT") do
      add :shape_id, :integer, primary_key: true
    end

    create table(:stops, primary_key: false, options: "STRICT") do
      add :stop_id, :integer, primary_key: true
      add :stop_name, :string, null: false
      add :stop_lat, :real, null: false
      add :stop_lon, :real, null: false
    end

    create table(:shape_points, primary_key: false, options: "STRICT") do
      add :shape_id,
          references(:shapes, column: :shape_id, type: :integer, on_delete: :delete_all),
          primary_key: true

      add :shape_pt_sequence, :integer, primary_key: true
      add :shape_lat, :real, null: false
      add :shape_lon, :real, null: false
    end

    create table(:trips, primary_key: false, options: "STRICT") do
      add :trip_id, :string, primary_key: true
      add :route_id, references(:routes, column: :route_id, type: :integer), null: false
      add :shape_id, references(:shapes, column: :shape_id, type: :integer)

      add :direction_id, :boolean,
        null: false,
        check: %{name: :trips_direction_id_check, expr: "direction_id IN (0, 1)"}

      add :frequency, :string,
        null: false,
        check: %{name: :trips_frequency_check, expr: "frequency IN ('F', 'L', 'S')"}
    end

    create table(:stop_times, primary_key: false, options: "STRICT") do
      add :trip_id,
          references(:trips, column: :trip_id, type: :string, on_delete: :delete_all),
          primary_key: true

      add :stop_id, references(:stops, column: :stop_id, type: :integer), primary_key: true

      add :stop_sequence, :integer, primary_key: true
      add :arrival_time, :integer, null: false
    end

    create index(:trips, [:route_id])
    create index(:stop_times, [:trip_id])
  end
end
