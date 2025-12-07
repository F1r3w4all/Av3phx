defmodule RideFastApi.Repo.Migrations.CreateLanguages do
  use Ecto.Migration

  def change do
    create table(:languages) do
      add :code, :string, size: 5, null: false
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    # Índice para garantir que não haja códigos de idioma duplicados
    create unique_index(:languages, [:code])
  end
end
