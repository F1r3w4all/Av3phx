# Conteúdo do novo arquivo YYYYMMDDHHMMSS_create_drivers_languages.exs
defmodule RideFastApi.Repo.Migrations.CreateDriversLanguages do
  use Ecto.Migration

  def change do
    create table(:drivers_languages) do
      add :driver_id, references(:drivers, on_delete: :delete_all), null: false
      add :language_id, references(:languages, on_delete: :delete_all), null: false
    end

    create unique_index(:drivers_languages, [:driver_id, :language_id])
  end
end
