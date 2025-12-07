defmodule RideFastApiWeb.UserJSON do
  alias RideFastApi.Accounts.User

  @doc """
  Renders a list of users, including pagination metadata.
  """
  # Corrigido para usar a função 'data/1' (que você definiu abaixo) e incluir 'meta'
  def index(%{users: users, meta: meta}) do
    %{
      data: for(user <- users, do: data(user)),
      meta: meta # Adicionado
    }
  end

  @doc """
  Renders a single user.
  """
  def show(%{user: user}) do
    %{data: data(user)}
  end

  # Corrigido para usar pattern matching no struct User diretamente, como no seu código original
  # Note que a assinatura de `data` na sua função era `data(%{user: user})`,
  # mas você a chamava diretamente com o struct `user` na compreensão de lista.
  # Vamos unificar para o padrão mais comum em Views/JSON (recebendo o struct):
  def data(%User{} = user) do
    %{
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      created_at: user.inserted_at,
      updated_at: user.updated_at
    }
  end
end
