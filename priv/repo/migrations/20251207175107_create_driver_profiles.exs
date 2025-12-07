defmodule RideFastApi.Repo.Migrations.CreateDriverProfiles do
  use Ecto.Migration

  def change do
    create table(:driver_profiles) do
      # Criação da Chave Estrangeira e Chave Primária Compartilhada (1-para-1)
      # :id é o campo principal aqui

      add :driver_id, references(:drivers, on_delete: :delete_all),
        null: false, type: :bigint, primary_key: true

      # Adicionar campos específicos do perfil do motorista
      add :address, :string
      add :city, :string
      add :state, :string
      add :zip_code, :string
      add :birth_date, :date
      add :cnh_number, :string # Número da Carteira Nacional de Habilitação
      add :cnh_category, :string

      timestamps(type: :utc_datetime)
    end

    # É crucial adicionar um índice único para garantir a relação 1-para-1
    create unique_index(:driver_profiles, [:driver_id])
  end
end
