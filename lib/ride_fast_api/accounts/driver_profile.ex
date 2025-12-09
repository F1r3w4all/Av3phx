defmodule RideFastApi.Accounts.DriverProfile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "driver_profiles" do
    belongs_to :driver, RideFastApi.Accounts.Driver, foreign_key: :driver_id

    field :license_number, :string
    field :license_expiry, :date
    field :background_check_ok, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(driver_profile, attrs) do
    driver_profile
    |> cast(attrs, [
      :driver_id,
      :license_number,
      :license_expiry,
      :background_check_ok
    ])
    |> validate_required([:driver_id, :license_number])
    |> unique_constraint(:driver_id)
    |> unique_constraint(:license_number)
    |> foreign_key_constraint(:driver_id)
  end
end
