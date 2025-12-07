# lib/ride_fast_api/accounts.ex

defmodule RideFastApi.Accounts do
  import Ecto.Query, warn: false
  alias RideFastApi.Repo
  alias RideFastApi.Accounts.{User, Driver}

  # CORREÇÃO: Usar o módulo principal Bcrypt, que é a estrutura padrão.
  import Bcrypt

  # --- Funções de CRUD (Publicadas para uso nos Controllers) ---

  # User (Passageiro)
  def list_users(params \\ %{}) do
  page = String.to_integer(params["page"] || "1")
  size = String.to_integer(params["size"] || "20") # Tamanho padrão da página

  # 1. Aplicar filtro (q)
  filtered_query =
    User
    |> apply_search_filter(params["q"])
    |> order_by([u], desc: u.inserted_at)

  # 2. Contar o total de registros (para a metadata)
  total_entries = Repo.aggregate(filtered_query, :count)

  # 3. Aplicar offset e limit (paginação manual)
  offset = (page - 1) * size

  users_query =
    filtered_query
    |> limit(^size)
    |> offset(^offset)

  # 4. Executar a consulta
  users = Repo.all(users_query)

  # 5. Calcular metadata da paginação
  meta = %{
    page: page,
    size: size,
    total_entries: total_entries,
    total_pages: ceil(total_entries / size)
  }

  {:ok, %{items: users, meta: meta}}
end
def get_user(id), do: Repo.get(User, id)
def get_driver(id), do: Repo.get(Driver, id)

# Função auxiliar para aplicar o filtro 'q' (permanece a mesma)
defp apply_search_filter(query, nil), do: query
defp apply_search_filter(query, q) do
  search_term = "%#{q}%"

  from u in query,
    where: ilike(u.email, ^search_term) or ilike(u.name, ^search_term)
end

  def get_user!(id), do: Repo.get!(User, id)

  def create_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def update_user(user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def delete_user(user) do
    Repo.delete(user)
  end

  # Driver (Motorista)
  def list_drivers, do: Repo.all(Driver)

  def get_driver!(id), do: Repo.get!(Driver, id)

  def create_driver(attrs) do
    %Driver{}
    |> Driver.registration_changeset(attrs)
    |> Repo.insert()
  end

  def update_driver(driver, attrs) do
    driver
    |> Driver.changeset(attrs)
    |> Repo.update()
  end

  def delete_driver(driver) do
    Repo.delete(driver)
  end


  # --- Função de Autenticação ---

  @doc """
  Tenta autenticar um usuário ou motorista (Driver) pelo email e senha.
  """
  def authenticate_user_or_driver(email, password) do
  # Primeiro tenta User
  case Repo.get_by(User, email: email) |> check_credentials(password) do
    {:ok, user} -> {:ok, user}
    _ ->
      # Depois tenta Driver
      case Repo.get_by(Driver, email: email) |> check_credentials(password) do
        {:ok, driver} -> {:ok, driver}
        _ -> {:error, :unauthorized}
      end
  end
end


  # --- Funções Auxiliares (Privadas) ---

  defp check_credentials(nil, _password), do: {:error, :not_found}

  defp check_credentials(entity, password) do
    # verify_pass/2 é fornecido pelo Bcrypt
    if verify_pass(password, entity.password_hash) do
      {:ok, entity}
    else
      {:error, :unauthorized}
    end
  end

end
