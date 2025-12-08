defmodule RideFastApi.Repo.Migrations.AddVehicleIdToRides do
  use Ecto.Migration

  def change do
    alter table(:rides) do
      add :vehicle_id, references(:vehicles)
    end

    create index(:rides, [:vehicle_id])
  end
end
