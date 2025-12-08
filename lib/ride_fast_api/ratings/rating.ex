defmodule RideFastApi.Ratings.Rating do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ratings" do
    belongs_to :ride, RideFastApi.Rides.Ride

    field :from_id, :integer
    field :to_id, :integer
    field :score, :integer
    field :comment, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(rating, attrs) do
    rating
    |> cast(attrs, [:ride_id, :from_id, :to_id, :score, :comment])
    |> validate_required([:ride_id, :from_id, :to_id, :score])
    |> validate_inclusion(:score, 1..5)
    |> unique_constraint([:ride_id, :from_id, :to_id])
  end
end
