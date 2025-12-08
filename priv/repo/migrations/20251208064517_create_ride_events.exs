defmodule RideFastApi.Repo.Migrations.CreateRideEvents do
  use Ecto.Migration

  def change do
    create table(:ride_events) do
      add :ride_id, references(:rides), null: false
      add :from_state, :string, null: false
      add :to_state, :string, null: false
      add :actor_role, :string, null: false   # "user" | "driver" | "admin"
      add :actor_id, :integer, null: false
      add :reason, :string

      timestamps(type: :utc_datetime)
    end

    create index(:ride_events, [:ride_id])
  end
end
