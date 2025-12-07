defmodule RideFastApiWeb.UserController do
  use RideFastApiWeb, :controller

  alias RideFastApi.Accounts
  alias RideFastApiWeb.UserJSON # Usaremos o UserJSON para renderizar
  alias RideFastApi.Guardian
  alias RideFastApi.Accounts.User

  action_fallback RideFastApiWeb.FallbackController

  # GET /api/v1/users (apenas admin)
  # A autorização "admin" é tratada pelo Plug AuthorizeAdmin no router.ex.
  def index(conn, params) do
    # 1. Trata os parâmetros de paginação e busca
    page  = Map.get(params, "page", "1")
    size  = Map.get(params, "size", "10")
    query = Map.get(params, "q", nil) # Use nil para o valor padrão de "q" (busca)

    # 2. Chama a função de contexto que implementa paginação e busca
    #    A função correta é list_users/1 que aceita o mapa de params.
    #    Assumimos que list_users/1 foi corrigida para usar os params
    case Accounts.list_users(%{"page" => page, "size" => size, "q" => query}) do
      {:ok, %{items: users, meta: meta}} ->
        conn
        |> put_status(:ok)
        |> render(UserJSON, :index, users: users, meta: meta)

      # Caso Accounts.list_users/1 retorne um erro (embora improvável aqui)
      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to list users: #{reason}"})
    end
  end

  # POST /api/users (Create)
  # Nota: Este endpoint geralmente não deveria estar no UserController se for apenas para passageiros/admins.
  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Accounts.create_user(user_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/v1/users/#{user.id}") # Corrigido para usar user.id
      |> render(UserJSON, :show, user: user) # Renderizando com UserJSON
    end
  end

  # GET /api/v1/users/:id (admin ou o próprio usuário)
  def show(conn, %{"id" => id}) do
    # O recurso atual já foi carregado pelo Guardian.
    current = Guardian.Plug.current_resource(conn)

    # 1. Tenta encontrar o usuário solicitado
    # Usamos get_user/1 (versão segura) para não lançar exceção.
    user = Accounts.get_user(id)

    cond do
      # 2. Se o usuário não for encontrado (e não cair no action_fallback)
      is_nil(user) ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "User not found"})

      # 3. Se for Admin
      current.role == "admin" ->
        # Renderiza o usuário encontrado
        render(conn, UserJSON, :show, user: user)

      # 4. Se for o próprio Usuário
      Integer.to_string(current.id) == id ->
        # Renderiza o recurso carregado (current) que é o mesmo usuário
        render(conn, UserJSON, :show, user: current)

      # 5. Outros casos (Acesso negado)
      true ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Forbidden"})
    end
  end

  # PUT /api/v1/users/:id
  def update(conn, %{"id" => id, "user" => user_params}) do
    # O código de autorização (se o usuário é admin ou o próprio) deveria estar aqui também.
    # Se você está usando o action_fallback, assumimos que o get_user! ou o find_user! lida com o erro 404.

    # É mais seguro usar get_user (sem !) e lidar com not_found
    case Accounts.get_user(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "User not found"})

      user ->
        with {:ok, %User{} = updated_user} <- Accounts.update_user(user, user_params) do
          render(conn, UserJSON, :show, user: updated_user)
        end
    end
  end

  # DELETE /api/v1/users/:id
  def delete(conn, %{"id" => id}) do
    # Novamente, a autorização (admin ou o próprio) deve ser verificada aqui.

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
