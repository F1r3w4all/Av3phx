defmodule RideFastApiWeb.UserJSON do
  alias RideFastApi.Accounts.User

  @doc """
  Renders a list of users.
  """
  def index(%{users: users}) do
    %{data: for(user <- users, do: data(user))}
  end

  @doc """
  Renders a single user.
  """
  def show(%{user: user}) do
    %{data: data(user)}
  end

  def data(%{user: user}) do
    %{
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      # CORREÇÃO: Usar inserted_at
      created_at: user.inserted_at,
      updated_at: user.updated_at
    }
  end
end
