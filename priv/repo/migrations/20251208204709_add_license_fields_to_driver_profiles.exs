defmodule RideFastApi.Repo.Migrations.AddLicenseFieldsToDriverProfiles do
  use Ecto.Migration

  def change do
    alter table(:driver_profiles) do
      add :license_number, :string
      add :license_expiry, :date
      add :background_check_ok, :boolean, default: false, null: false
      remove :address
      remove :city
      remove :state
      remove :zip_code
      remove :birth_date
      remove :cnh_number
      remove :cnh_category
    end

    create unique_index(:driver_profiles, [:license_number])
  end
end
