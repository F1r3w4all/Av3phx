defmodule RideFastApi.Accounts.Vehicle do
  use Ecto.Schema
  import Ecto.Changeset

  schema "vehicles" do
    # O veículo pertence a um Driver.
    belongs_to :driver, RideFastApi.Accounts.Driver, foreign_key: :driver_id

    field :plate, :string
    field :brand, :string
    field :model, :string
    field :color, :string
    field :year, :integer
    field :renavam, :string
    field :chassis, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(vehicle, attrs) do
    vehicle
    |> cast(attrs, [:plate, :brand, :model, :color, :year, :renavam, :chassis, :driver_id])
    |> validate_required([:plate, :brand, :model, :year, :driver_id, :renavam, :chassis])
    |> validate_length(:plate, is: 7)
    |> unique_constraint(:plate)
    |> unique_constraint(:renavam)
    |> unique_constraint(:chassis)
    |> foreign_key_constraint(:driver_id)
  end
end
