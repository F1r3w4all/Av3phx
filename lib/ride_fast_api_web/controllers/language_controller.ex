defmodule RideFastApiWeb.LanguageController do
  use RideFastApiWeb, :controller

  alias RideFastApi.Accounts
  alias RideFastApi.Accounts.Language

  action_fallback(RideFastApiWeb.FallbackController)

  def create(conn, params) do
    with {:ok, %Language{} = language} <- Accounts.create_language(params) do
      conn
      |> put_status(:created)
      |> json(%{
        id: language.id,
        code: language.code,
        name: language.name
      })
    end
  end

  def index(conn, _params) do
    languages = Accounts.list_languages()

    json(conn, %{
      data:
        Enum.map(languages, fn lang ->
          %{
            id: lang.id,
            code: lang.code,
            name: lang.name
          }
        end)
    })
  end
end
