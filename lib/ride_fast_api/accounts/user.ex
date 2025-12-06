# lib/ride_fast_api/accounts/user.ex

defmodule RideFastApi.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  # CORREÇÃO: Usar o módulo principal Bcrypt
  import Bcrypt

  schema "users" do
    field :name, :string
    field :email, :string
    field :phone, :string
    field :password_hash, :string

    field :password, :string, virtual: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  # Changeset para ATUALIZAÇÃO
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :phone])
    |> validate_required([:name, :email, :phone])
    |> unique_constraint(:email)
  end

  @doc false
  # Changeset para REGISTRO
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :phone, :password])
    |> validate_required([:name, :email, :phone, :password])
    |> validate_length(:password, min: 8)
    |> unique_constraint(:email)
    |> put_password_hash() # Insere o hash Bcrypt
  end

  # Função auxiliar para hashear a senha
  defp put_password_hash(changeset) do
    case fetch_change(changeset, :password) do
      {:ok, password} when is_binary(password) and password != "" ->

        # CORREÇÃO: Usar a função moderna do Bcrypt: hash_pwd_salt/1
        password_hash = hash_pwd_salt(password)

        changeset
        |> put_change(:password_hash, password_hash)
        |> delete_change(:password)
      _ ->
        changeset
    end
  end
end
