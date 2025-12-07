defmodule RideFastApi.Accounts.Language do
  use Ecto.Schema
  import Ecto.Changeset

  schema "languages" do
    # CORREÇÃO: Remova a opção ':size'. Ecto não a aceita em 'field/3'.
    # A restrição de tamanho é feita na migration.
    field :code, :string
    field :name, :string

    # Relação Muitos-para-Muitos inversa (opcional, mas boa prática)
    many_to_many :drivers, RideFastApi.Accounts.Driver,
      join_through: "drivers_languages"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(language, attrs) do
    language
    |> cast(attrs, [:code, :name])
    |> validate_required([:code, :name])
    |> unique_constraint(:code)
  end
end
