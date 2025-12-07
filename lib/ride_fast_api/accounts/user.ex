defmodule RideFastApi.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Bcrypt

  schema "users" do
    field :name, :string
    field :email, :string
    field :phone, :string
    field :password_hash, :string
    field :role, :string  # <-- REMOVER default aqui (IMPORTANTE)

    field :password, :string, virtual: true

    timestamps(type: :utc_datetime)
  end

  @roles ~w(user admin)

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :phone, :role])
    |> validate_required([:name, :email, :phone, :role])
    |> validate_inclusion(:role, @roles)
    |> unique_constraint(:email)
  end

  @doc false
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :phone, :password, :role])
    |> validate_required([:name, :email, :phone, :password, :role])
    |> validate_length(:password, min: 8)
    |> validate_inclusion(:role, @roles)
    |> unique_constraint(:email)
    |> put_password_hash()
  end

  defp put_password_hash(changeset) do
    case fetch_change(changeset, :password) do
      {:ok, password} when is_binary(password) and password != "" ->
        changeset
        |> put_change(:password_hash, Bcrypt.hash_pwd_salt(password))
        |> delete_change(:password)

      _ ->
        changeset
    end
  end
end
