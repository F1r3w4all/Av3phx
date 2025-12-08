defmodule RideFastApi.Repo.Migrations.AddEndedAtAndFinalPriceToRides do
  use Ecto.Migration

  def change do
    alter table(:rides) do
      add :ended_at, :utc_datetime
      add :final_price, :decimal, precision: 10, scale: 2
    end
  end
end
