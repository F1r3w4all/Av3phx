defmodule RideFastApi.Accounts.Driver do
  use Ecto.Schema
  import Ecto.Changeset
  import Bcrypt

  alias RideFastApi.Accounts.Language
  alias RideFastApi.Repo

  schema "drivers" do
    field :name, :string
    field :email, :string
    field :phone, :string
    field :password_hash, :string
    field :status, :string
    field :password, :string, virtual: true
    has_many :vehicles, RideFastApi.Accounts.Vehicle, foreign_key: :driver_id, where: [deleted_at: nil]
    has_one :profile, RideFastApi.Accounts.DriverProfile, foreign_key: :driver_id

    many_to_many :languages, Language,
      join_through: "drivers_languages",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  # ------------------------------------------------------------
  # CHANGESET PARA ATUALIZAÇÃO
  # ------------------------------------------------------------
  def changeset(driver, attrs) do
    driver
    |> cast(attrs, [:name, :email, :phone, :status])
    |> validate_required([:name, :email, :phone, :status])
    |> unique_constraint(:email)
    |> maybe_put_languages(attrs)
  end

  # ------------------------------------------------------------
  # CHANGESET PARA REGISTRO (inclui password)
  # ------------------------------------------------------------
  def registration_changeset(driver, attrs) do
    driver
    |> cast(attrs, [:name, :email, :phone, :status, :password])
    |> validate_required([:name, :email, :phone, :status, :password])
    |> validate_length(:password, min: 8)
    |> unique_constraint(:email)
    |> put_password_hash()
    |> maybe_put_languages(attrs)
  end

  # ------------------------------------------------------------
  # ASSOCIAÇÃO DE LINGUAGENS (aceita lista de IDs ou códigos)
  # ------------------------------------------------------------
  defp maybe_put_languages(changeset, %{"languages" => langs}) when is_list(langs) do
    languages = fetch_languages(langs)
    put_assoc(changeset, :languages, languages)
  end

  defp maybe_put_languages(changeset, %{languages: langs}) when is_list(langs) do
    languages = fetch_languages(langs)
    put_assoc(changeset, :languages, languages)
  end

  defp maybe_put_languages(changeset, _), do: changeset

  # Converte IDs ou códigos em registros de Language
  defp fetch_languages(list) do
    list
    |> Enum.map(fn
      id when is_integer(id) ->
        Repo.get(Language, id)

      code when is_binary(code) ->
        # Se o JSON mandar ["pt-BR"] e isso estiver em Language.code:
        Repo.get_by(Language, code: code)
        # Se você quiser usar o campo name em vez de code, troque para:
        # Repo.get_by(Language, name: code)
    end)
    |> Enum.reject(&is_nil/1)
  end

  # ------------------------------------------------------------
  # SENHA
  # ------------------------------------------------------------
  defp put_password_hash(changeset) do
    case fetch_change(changeset, :password) do
      {:ok, password} when is_binary(password) and password != "" ->
        changeset
        |> put_change(:password_hash, Bcrypt.hash_pwd_salt(password))
        |> delete_change(:password)

      _ ->
        changeset
    end
  end
end
