# lib/ride_fast_api/guardian.ex

defmodule RideFastApi.Guardian do
  use Guardian, otp_app: :ride_fast_api

  alias RideFastApi.Accounts

  # --- 1. Funções de Comportamento Guardian Obrigatórias (@impl true) ---

  # Define qual campo será o "sujeito" (sub) do token. Usamos o ID.
  @impl true
  def subject_for_token(resource, _claims) do
    {:ok, to_string(resource.id)}
  end

  # O Guardian 2.x utiliza resource_to_claims para definir o payload.
  @impl true
  def resource_to_claims(resource, _claims) do
    {:ok, %{
      id: to_string(resource.id),
      role: resource.role
    }}
  end

  # Implementa resource_from_claims/1 (Exigido pelo Guardian)
  # Ele chama a nossa função interna de busca por User/Driver.
  @impl true
  def resource_from_claims(claims), do: from_claims(claims)

  # --- 2. Função de Serialização (Busca a entidade no DB) ---

  # Esta é a função que busca o User ou Driver baseado nos claims do token.
  defp from_claims(%{"id" => id, "role" => role} = _claims) do
    case role do
      "user" ->
        case Accounts.get_user!(id) do
          nil -> {:error, "User not found"}
          user -> {:ok, Map.put(user, :role, "user")}
        end

      "driver" ->
        case Accounts.get_driver!(id) do
          nil -> {:error, "Driver not found"}
          driver -> {:ok, Map.put(driver, :role, "driver")}
        end

      _ -> {:error, "Invalid role"}
    end
  end

  defp from_claims(_claims), do: {:error, "Missing claims"}


  # --- 3. Wrapper para Emissão do Token (Para uso no AuthController) ---

  @doc "Gera um token JWT para a entidade (User ou Driver)."
  def issue(resource, claims \\ %{}) do
    resource_claims = Map.take(resource, [:id, :role])

    # CORREÇÃO: Usamos o Guardian.Token.issue/2 para evitar o warning
    with {:ok, token, full_claims} <- Guardian.Token.issue(resource, resource_claims |> Map.merge(claims)) do
      {:ok, token, full_claims}
    else
      {:error, reason} -> {:error, reason}
    end
  end

end
