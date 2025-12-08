defmodule RideFastApi.Rides.RideEvent do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ride_events" do
    belongs_to :ride, RideFastApi.Rides.Ride

    field :from_state, :string
    field :to_state, :string
    field :actor_role, :string
    field :actor_id, :integer
    field :reason, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:ride_id, :from_state, :to_state, :actor_role, :actor_id, :reason])
    |> validate_required([:ride_id, :from_state, :to_state, :actor_role, :actor_id])
  end
end
