defmodule RideFastApiWeb.UserController do
  use RideFastApiWeb, :controller

  alias RideFastApi.Accounts
  alias RideFastApiWeb.UserJSON
  alias RideFastApi.Guardian
  alias RideFastApi.Accounts.User
  # Alias necessário para tratar o 400 Bad Request
  alias RideFastApiWeb.ErrorJSON

  action_fallback RideFastApiWeb.FallbackController

  # GET /api/v1/users (apenas admin)
  def index(conn, params) do
    # A autorização "admin" é tratada pelo Plug AuthorizeAdmin no router.ex.
    page  = Map.get(params, "page", "1")
    size  = Map.get(params, "size", "10")
    query = Map.get(params, "q", nil)

    case Accounts.list_users(%{"page" => page, "size" => size, "q" => query}) do
      {:ok, %{items: users, meta: meta}} ->
        conn
        |> put_status(:ok)
        |> render(UserJSON, :index, users: users, meta: meta)

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to list users: #{reason}"})
    end
  end

  # POST /api/users (Create)
  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Accounts.create_user(user_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/v1/users/#{user.id}")
      |> render(UserJSON, :show, user: user)
    end
  end

  # GET /api/v1/users/:id (admin ou o próprio usuário)
  def show(conn, %{"id" => id}) do
    current = Guardian.Plug.current_resource(conn)
    user = Accounts.get_user(id)

    cond do
      # 404 Not Found
      is_nil(user) ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "User not found"})

      # 200 OK (Admin)
      current.role == "admin" ->
        render(conn, UserJSON, :show, user: user)

      # 200 OK (Próprio Usuário)
      Integer.to_string(current.id) == id ->
        render(conn, UserJSON, :show, user: current)

      # 403 Forbidden
      true ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Forbidden"})
    end
  end

  # PUT /api/v1/users/:id (CORRIGIDO PARA ACEITAR PARÂMETROS FLAT)
  def update(conn, %{"id" => id} = params) do
    # Extrai os parâmetros de atualização, removendo o "id" da URL
    user_params = Map.delete(params, "id")

    current = Guardian.Plug.current_resource(conn)

    # Verifica se é Admin OU se é o próprio usuário
    is_admin = current.role == "admin"
    is_self = Integer.to_string(current.id) == id

    unless is_admin or is_self do
      # --- 403 Forbidden ---
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Forbidden. You can only update your own profile."})
      |> halt()
    end

    # Busca o usuário que será atualizado
    case Accounts.get_user(id) do
      nil ->
        # --- 404 Not Found ---
        conn
        |> put_status(:not_found)
        |> json(%{error: "User not found"})

      user ->
        # Tenta atualizar o perfil
        case Accounts.update_user(user, user_params) do
          {:ok, %User{} = updated_user} ->
            # --- 200 OK ---
            render(conn, UserJSON, :show, user: updated_user)

          # Lida com erros de validação
          {:error, %Ecto.Changeset{} = changeset} ->
            # --- 400 Bad Request ---
            conn
            |> put_status(:bad_request)
            |> render(ErrorJSON, :bad_request, changeset: changeset)
        end
    end
  end

  # DELETE /api/v1/users/:id (Autorização deve ser adicionada aqui também)
  def delete(conn, %{"id" => id}) do
    current = Guardian.Plug.current_resource(conn)

    # Verifica se é Admin OU se é o próprio usuário
    is_admin = current.role == "admin"
    is_self = Integer.to_string(current.id) == id

    unless is_admin or is_self do
      # --- 403 Forbidden ---
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Forbidden. You can only delete your own profile."})
      |> halt()
    end

    # Busca e deleta
    case Accounts.get_user(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "User not found"})

      user ->
        with {:ok, %User{}} <- Accounts.delete_user(user) do
          send_resp(conn, :no_content, "")
        end
    end
  end
end
