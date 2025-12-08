defmodule RideFastApi.Repo.Migrations.AddStartedAtToRides do
  use Ecto.Migration

  def change do
    alter table(:rides) do
      add :started_at, :utc_datetime
    end
  end
end
