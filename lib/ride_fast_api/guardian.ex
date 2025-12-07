defmodule RideFastApi.Guardian do
  use Guardian, otp_app: :ride_fast_api

  alias RideFastApi.Accounts

  @impl true
  def subject_for_token(resource, _claims) do
    {:ok, to_string(resource.id)}
  end

  @impl true
  def resource_to_claims(resource, _claims) do
    # É crucial garantir que o resource.role exista
    {:ok, %{id: to_string(resource.id), role: resource.role}}
  end


  @impl true
  def resource_from_claims(%{"sub" => id}) do
    case Accounts.get_user(String.to_integer(id)) do
      nil -> {:error, :resource_not_found}
      user -> {:ok, user}
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
  def issue(%{role: role} = resource) do
    extra_claims = %{"role" => role, "typ" => "access"}
    encode_and_sign(resource, extra_claims)
  end
end
