defmodule RideFastApiWeb.Plugs.AuthorizeAdmin do
  import Plug.Conn
  alias RideFastApi.Guardian

  def init(opts), do: opts

  def call(conn, _opts) do
    claims = Guardian.Plug.current_claims(conn)
    role   = claims && claims["role"]

    if role == "admin" do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> Phoenix.Controller.json(%{error: "Forbidden"})
      |> halt()
    end
  end
end
