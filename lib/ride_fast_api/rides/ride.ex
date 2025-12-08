defmodule RideFastApi.Rides.Ride do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rides" do
    belongs_to :user, RideFastApi.Accounts.User
    belongs_to :driver, RideFastApi.Accounts.Driver

    belongs_to :vehicle, RideFastApi.Accounts.Vehicle

    field :status, :string
    field :origin_lat, :float
    field :origin_lng, :float
    field :destination_lat, :float
    field :destination_lng, :float
    field :payment_method, :string
    field :started_at, :utc_datetime
    field :ended_at, :utc_datetime
    field :final_price, :decimal
    field :cancel_reason, :string
    field :canceled_by, :string

    timestamps(type: :utc_datetime)
  end

  @valid_statuses ~w(SOLICITADA ACEITA EM_ANDAMENTO FINALIZADA CANCELADA)

  def create_changeset(ride, attrs) do
    ride
    |> cast(attrs, [
      :user_id,
      :origin_lat,
      :origin_lng,
      :destination_lat,
      :destination_lng,
      :payment_method
    ])
    |> validate_required([
      :user_id,
      :origin_lat,
      :origin_lng,
      :destination_lat,
      :destination_lng,
      :payment_method
    ])
    |> validate_inclusion(:payment_method, ["CARD", "CASH"])
    |> put_change(:status, "SOLICITADA")
    |> validate_inclusion(:status, @valid_statuses)
  end
end
