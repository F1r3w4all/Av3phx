defmodule RideFastApiWeb.Plugs.AuthorizeAdmin do
  import Plug.Conn
  alias RideFastApi.Guardian

  def init(opts), do: opts

  def call(conn, _opts) do
    case Guardian.Plug.current_resource(conn) do
      %{role: "admin"} ->
        conn

      _ ->
        conn
        |> send_resp(403, ~s({"error":"forbidden"}))
        |> halt()
    end
  end
end
