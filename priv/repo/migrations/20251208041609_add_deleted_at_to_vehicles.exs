defmodule RideFastApi.Repo.Migrations.AddDeletedAtToVehicles do
  use Ecto.Migration

  def change do
    alter table(:vehicles) do
      add :deleted_at, :utc_datetime
    end
  end
end
