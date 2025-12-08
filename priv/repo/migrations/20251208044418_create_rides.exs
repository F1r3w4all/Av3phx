defmodule RideFastApi.Repo.Migrations.CreateRides do
  use Ecto.Migration

  def change do
    create table(:rides) do
      add :user_id, references(:users), null: false
      add :driver_id, references(:drivers)
      add :status, :string, null: false

      add :origin_lat, :float, null: false
      add :origin_lng, :float, null: false
      add :destination_lat, :float, null: false
      add :destination_lng, :float, null: false

      add :payment_method, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:rides, [:user_id])
    create index(:rides, [:driver_id])
  end
end
