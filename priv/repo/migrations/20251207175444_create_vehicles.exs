defmodule RideFastApi.Repo.Migrations.CreateVehicles do
  use Ecto.Migration

  def change do
    create table(:vehicles) do
      # Criação da Chave Estrangeira que referencia o Driver
      add :driver_id, references(:drivers, on_delete: :delete_all), null: false

      # Campos específicos do veículo
      add :plate, :string, size: 7, null: false # Ex: AAA9A99 ou AAA9999
      add :brand, :string
      add :model, :string
      add :color, :string
      add :year, :integer
      add :renavam, :string, null: false, unique: true
      add :chassis, :string, null: false, unique: true

      timestamps(type: :utc_datetime)
    end

    # Índices para consultas rápidas e para garantir a unicidade da placa
    create unique_index(:vehicles, [:plate])
    create index(:vehicles, [:driver_id])
  end
end
