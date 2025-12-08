defmodule RideFastApi.Accounts do
  import Ecto.Query, warn: false
  alias RideFastApi.Repo
  alias RideFastApi.Accounts.Language
  alias RideFastApi.Accounts.{User, Driver, DriverProfile, Vehicle}

  import Bcrypt

  # ============================================================
  # USERS
  # ============================================================

  def list_users(params \\ %{}) do
    page = String.to_integer(params["page"] || "1")
    size = String.to_integer(params["size"] || "20")

    filtered_query =
      User
      |> apply_search_filter(params["q"])
      |> order_by([u], desc: u.inserted_at)

    total_entries = Repo.aggregate(filtered_query, :count)
    offset = (page - 1) * size

    users =
      filtered_query
      |> limit(^size)
      |> offset(^offset)
      |> Repo.all()

    meta = %{
      page: page,
      size: size,
      total_entries: total_entries,
      total_pages: ceil(total_entries / size)
    }

    {:ok, %{items: users, meta: meta}}
  end

  @doc """
  Busca um motorista pelo ID e carrega (preloads) suas associações.
  """
  def get_driver_with_details(id) do
    Driver
    |> Repo.get(id)
    |> Repo.preload([:profile, :vehicles, :languages])
  end

  def get_user(id), do: Repo.get(User, id)
  def get_driver(id), do: Repo.get(Driver, id)

  defp apply_search_filter(query, nil), do: query

  defp apply_search_filter(query, q) do
    search_term = "%#{q}%"

    from(u in query,
      where: ilike(u.email, ^search_term) or ilike(u.name, ^search_term)
    )
  end

  def get_user!(id), do: Repo.get!(User, id)

  def create_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def update_user(user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def delete_user(user) do
    Repo.delete(user)
  end

  # ============================================================
  # DRIVERS
  # ============================================================

  def list_drivers(params \\ %{}) do
    page = String.to_integer(Map.get(params, "page", "1"))
    size = String.to_integer(Map.get(params, "size", "20"))

    query =
      Driver
      |> apply_status_filter(params["status"])
      # Removido apply_language_filter por enquanto; many_to_many não tem campo language direto
      |> order_by([d], desc: d.inserted_at)

    total_entries = Repo.aggregate(query, :count)
    offset = (page - 1) * size

    drivers =
      query
      |> limit(^size)
      |> offset(^offset)
      |> Repo.all()

    meta = %{
      page: page,
      size: size,
      total_entries: total_entries,
      total_pages: ceil(total_entries / size)
    }

    {:ok, %{items: drivers, meta: meta}}
  end

  defp apply_status_filter(query, nil), do: query

  defp apply_status_filter(query, status) do
    from(d in query,
      where: d.status == ^status
    )
  end

  # (Filtro por idioma via many_to_many pode ser implementado depois com join)

  def get_driver!(id), do: Repo.get!(Driver, id)

  # Usado tanto pelo /auth/register quanto pelo POST /api/v1/drivers (admin)
  def create_driver(attrs) do
    %Driver{}
    |> Driver.registration_changeset(attrs)
    |> Repo.insert()

    # Se quiser transformar conflito de e-mail em {:error, :email_conflict}, pode fazer:
    # |> handle_driver_insert_conflicts()
  end

  # Opcional: diferenciar 400 x 409
  # defp handle_driver_insert_conflicts({:ok, driver}), do: {:ok, driver}
  #
  # defp handle_driver_insert_conflicts({:error, %Ecto.Changeset{} = changeset}) do
  #   case changeset.errors do
  #     [email: {_msg, [constraint: :unique, constraint_name: _]} | _] ->
  #       {:error, :email_conflict}
  #
  #     _ ->
  #       {:error, changeset}
  #   end
  # end

  def update_driver(driver, attrs) do
    driver
    |> Driver.changeset(attrs)
    |> Repo.update()
  end

  def delete_driver(driver) do
    Repo.delete(driver)
  end

  # ============================================================
  # AUTENTICAÇÃO
  # ============================================================

  @doc """
  Tenta autenticar um usuário ou motorista (Driver) pelo email e senha.
  """
  def authenticate_user_or_driver(email, password) do
    case Repo.get_by(User, email: email) |> check_credentials(password) do
      {:ok, user} ->
        {:ok, user}

      _ ->
        case Repo.get_by(Driver, email: email) |> check_credentials(password) do
          {:ok, driver} -> {:ok, driver}
          _ -> {:error, :unauthorized}
        end
    end
  end

  defp check_credentials(nil, _password), do: {:error, :not_found}

  defp check_credentials(entity, password) do
    if verify_pass(password, entity.password_hash) do
      {:ok, entity}
    else
      {:error, :unauthorized}
    end
  end

  def create_driver_profile(attrs) do
    %DriverProfile{}
    |> DriverProfile.changeset(attrs)
    |> Repo.insert()
  end

  def update_driver_profile(profile, attrs) do
    profile
    |> DriverProfile.changeset(attrs)
    |> Repo.update()
  end

  def create_vehicle(attrs) do
    %Vehicle{}
    |> Vehicle.changeset(attrs)
    |> Repo.insert()
  end

  def create_language(attrs) do
    %Language{}
    |> Language.changeset(attrs)
    |> Repo.insert()
  end

  def list_languages do
    Repo.all(Language)
  end

  def associate_driver_language(driver_id, language_id)
      when is_integer(driver_id) and is_integer(language_id) do
    case {Repo.get(Driver, driver_id), Repo.get(Language, language_id)} do
      {nil, _} ->
        {:error, :not_found_driver}

      {_, nil} ->
        {:error, :not_found_language}

      {_driver, _language} ->
        existing_query =
          from dl in "drivers_languages",
            where: dl.driver_id == ^driver_id and dl.language_id == ^language_id,
            select: dl.driver_id

        case Repo.one(existing_query) do
          # já existe associação
          ^driver_id ->
            {:error, :already_exists}

          nil ->
            case Repo.insert_all("drivers_languages", [
                   %{driver_id: driver_id, language_id: language_id}
                 ]) do
              {1, _} -> {:ok, :created}
              {0, _} -> {:error, :insert_failed}
            end
        end
    end
  rescue
    e -> {:error, e}
  end

  def remove_language_from_driver(driver_id, language_id) do
    query =
      from(dl in "drivers_languages",
        where: dl.driver_id == ^driver_id and dl.language_id == ^language_id
      )

    case Repo.delete_all(query) do
      {1, _} ->
        {:ok, :removed}

      {0, _} ->
        {:error, :not_found}
    end
  end

  def list_languages_for_driver(driver_id) do
    alias RideFastApi.Repo
    alias RideFastApi.Accounts.Driver

    case Repo.get(Driver, driver_id) do
      nil ->
        {:error, :not_found}

      %Driver{} = driver ->
        # garanta que languages esteja preloaded
        driver = Repo.preload(driver, :languages)
        {:ok, driver.languages || []}
    end
  end
end
