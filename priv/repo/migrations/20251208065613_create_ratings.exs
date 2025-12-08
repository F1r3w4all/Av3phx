defmodule RideFastApi.Repo.Migrations.CreateRatings do
  use Ecto.Migration

  def change do
    create table(:ratings) do
      add :ride_id, references(:rides), null: false
      add :from_id, :integer, null: false
      add :to_id, :integer, null: false
      add :score, :integer, null: false
      add :comment, :string

      timestamps(type: :utc_datetime)
    end

    create index(:ratings, [:ride_id])

    # opcional: 1 avaliação por (ride, from_id, to_id)
    create unique_index(:ratings, [:ride_id, :from_id, :to_id])
  end
end
