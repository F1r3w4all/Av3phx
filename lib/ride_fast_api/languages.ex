defmodule RideFastApi.Languages do
  @moduledoc """
  Contexto para Languages (idiomas).
  """

  import Ecto.Query, warn: false
  alias RideFastApi.Repo
  alias RideFastApi.Accounts.Language

  @doc "Retorna todas as languages ordenadas por nome."
  def list_languages do
    Language
    |> order_by(asc: :name)
    |> Repo.all()
  end

  @doc "Retorna uma language por id (ou nil)."
  def get_language(id) when is_binary(id) do
    case Integer.parse(id) do
      {int, _} -> get_language(int)
      :error -> nil
    end
  end

  def get_language(id) when is_integer(id) do
    Repo.get(Language, id)
  end

  def create_language(attrs) do
    %Language{}
    |> Language.changeset(attrs)
    |> Repo.insert()
  end
end
