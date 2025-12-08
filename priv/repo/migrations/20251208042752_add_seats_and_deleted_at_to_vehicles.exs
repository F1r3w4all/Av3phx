defmodule RideFastApi.Repo.Migrations.AddSeatsAndDeletedAtToVehicles do
  use Ecto.Migration

  def change do
    alter table(:vehicles) do
      add :seats, :integer

    end
  end
end
