defmodule RideFastApi.Accounts.Vehicle do
  use Ecto.Schema
  import Ecto.Changeset

  schema "vehicles" do
    belongs_to :driver, RideFastApi.Accounts.Driver, foreign_key: :driver_id

    field :plate, :string
    field :model, :string
    field :color, :string
    field :seats, :integer
    field :deleted_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(vehicle, attrs) do
    vehicle
    |> cast(attrs, [:driver_id, :plate, :model, :color, :seats, :deleted_at])
    |> validate_required([:driver_id, :plate, :model, :color, :seats])
    |> unique_constraint(:plate)
  end
end
