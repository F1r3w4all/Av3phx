# lib/ride_fast_api/accounts.ex

defmodule RideFastApi.Accounts do
  import Ecto.Query, warn: false
  alias RideFastApi.Repo
  alias RideFastApi.Accounts.{User, Driver}

  # CORREÇÃO: Usar o módulo principal Bcrypt, que é a estrutura padrão.
  import Bcrypt

  # --- Funções de CRUD (Publicadas para uso nos Controllers) ---

  # User (Passageiro)
  def list_users, do: Repo.all(User)

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
