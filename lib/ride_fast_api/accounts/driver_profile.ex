defmodule RideFastApi.Accounts.DriverProfile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "driver_profiles" do
    # Campo para a relação 1-para-1. O `DriverProfile` pertence a um `Driver`.
   belongs_to :driver, RideFastApi.Accounts.Driver, foreign_key: :driver_id

    field :address, :string
    field :city, :string
    field :state, :string
    field :zip_code, :string
    field :birth_date, :date
    field :cnh_number, :string
    field :cnh_category, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(driver_profile, attrs) do
  driver_profile
  |> cast(attrs, [
    :address,
    :city,
    :state,
    :zip_code,
    :birth_date,
    :cnh_number,
    :cnh_category,
    :driver_id
  ])
  |> validate_required([:driver_id, :cnh_number])
  |> unique_constraint(:driver_id)
  |> unique_constraint(:cnh_number)
  |> foreign_key_constraint(:driver_id)
end
end
