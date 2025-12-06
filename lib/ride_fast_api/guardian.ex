defmodule RideFastApi.Guardian do
  use Guardian, otp_app: :ride_fast_api

  alias RideFastApi.Accounts

  @impl true
  def subject_for_token(resource, _claims) do
    {:ok, to_string(resource.id)}
  end

  @impl true
  def resource_to_claims(resource, _claims) do
    {:ok, %{id: to_string(resource.id), role: resource.role}}
  end

  @impl true
  def resource_from_claims(claims), do: from_claims(claims)

  defp from_claims(%{"id" => id, "role" => role}) do
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

      _ ->
        {:error, "Invalid role"}
    end
  end

  defp from_claims(_claims), do: {:error, "Missing claims"}

  @doc "Gera um token JWT para a entidade (User ou Driver)."
  def issue(resource, extra_claims \\ %{}) do
    claims = Map.merge(%{role: resource.role}, extra_claims)
    encode_and_sign(resource, claims)
  end
end
