defmodule RideFastApi.Repo.Migrations.AddCancelFieldsToRides do
  use Ecto.Migration

  def change do
    alter table(:rides) do
      add :cancel_reason, :string
      add :canceled_by, :string  # "user" | "driver" | "admin"
    end
  end
end
