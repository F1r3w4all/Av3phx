defmodule RideFastApi.Guardian do
  use Guardian, otp_app: :ride_fast_api

  alias RideFastApi.Accounts

  @impl true
  @impl true
  def subject_for_token(%Accounts.User{id: id}, _claims), do: {:ok, "user:#{id}"}

  @impl true
  def subject_for_token(%Accounts.Driver{id: id}, _claims), do: {:ok, "driver:#{id}"}

  @impl true
  def subject_for_token(resource, _claims),
    do: {:ok, to_string(resource.id)}

  @impl true
def resource_from_claims(%{"sub" => "user:" <> id}) do
  case Accounts.get_user(String.to_integer(id)) do
    nil -> {:error, :resource_not_found}
    user -> {:ok, Map.put(user, :role, "user")}
  end
end

@impl true
def resource_from_claims(%{"sub" => "driver:" <> id}) do
  case Accounts.get_driver(String.to_integer(id)) do
    nil -> {:error, :resource_not_found}
    driver -> {:ok, Map.put(driver, :role, "driver")}
  end
end

def resource_from_claims(_), do: {:error, :invalid_claims}

  # --- Função Principal para buscar o Recurso ---
  defp from_claims(%{"id" => id, "role" => role}) do
    # 1. Converter ID para inteiro (necessário para buscar no Repo/Ecto)
    int_id = String.to_integer(id)

    # 2. Lógica para buscar o Recurso baseado na Role
    case role do
      "user" ->
        # Utiliza get_user/1 (versão segura)
        case Accounts.get_user(int_id) do
          nil -> {:error, "User not found"}
          user -> {:ok, Map.put(user, :role, "user")}
        end

      "driver" ->
        # Utiliza get_driver/1 (versão segura)
        case Accounts.get_driver(int_id) do
          nil -> {:error, "Driver not found"}
          driver -> {:ok, Map.put(driver, :role, "driver")}
        end

      "admin" ->
        # Lógica de admin (assumindo que admins são Users). Utiliza get_user/1
        case Accounts.get_user(int_id) do
          nil -> {:error, "Admin not found (or user deleted)"}
          admin -> {:ok, Map.put(admin, :role, "admin")}
        end

      _ ->
        {:error, "Invalid role"}
    end
  end

  # --- Fim da Função Principal ---

  # Cláusula para lidar com claims faltando
  defp from_claims(_claims), do: {:error, "Missing claims"}

  @doc "Gera um token JWT para a entidade (User ou Driver)."

  @doc "Gera um token JWT para User."
  def issue(%Accounts.User{} = user) do
    # garante que user.role exista (user/admin)
    role = Map.get(user, :role, "user")
    extra_claims = %{"role" => role, "typ" => "access"}
    encode_and_sign(user, extra_claims)
  end

  @doc "Gera um token JWT para Driver."
  def issue(%Accounts.Driver{} = driver) do
    # aqui o papel é sempre 'driver'
    driver_with_role = Map.put(driver, :role, "driver")
    extra_claims = %{"role" => "driver", "typ" => "access"}
    encode_and_sign(driver_with_role, extra_claims)
  end

  def issue(%{role: role} = resource) do
    extra_claims = %{"role" => role, "typ" => "access"}
    encode_and_sign(resource, extra_claims)
  end
end
