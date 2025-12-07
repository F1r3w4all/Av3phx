defmodule RideFastApiWeb.AuthErrorHandler do
  import Plug.Conn
  import Phoenix.Controller

  def auth_error(conn, {type, _reason}, _opts) do
    body =
      case type do
        :unauthenticated -> %{error: "Unauthorized"}
        :unauthorized -> %{error: "Forbidden"}
        _ -> %{error: "Authentication error"}
      end

    conn
    |> put_status(:unauthorized)
    |> put_view(RideFastApiWeb.ErrorJSON)
    |> json(body)
  end
end
