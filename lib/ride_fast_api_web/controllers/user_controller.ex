defmodule RideFastApiWeb.UserController do
  use RideFastApiWeb, :controller

  alias RideFastApi.Accounts
  alias RideFastApi.Accounts.User
  alias RideFastApi.Guardian

  action_fallback RideFastApiWeb.FallbackController

  # GET /api/v1/users  (apenas admin)
  def index(conn, params) do
    current = Guardian.Plug.current_resource(conn)

    if current.role == "admin" do
      page  = Map.get(params, "page", "1")
      size  = Map.get(params, "size", "10")
      query = Map.get(params, "q", "")

      users = Accounts.list_users_paginated(page, size, query)
      json(conn, users)
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Forbidden"})
    end
  end

  # POST /api/users  (caso ainda use create na API)
  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Accounts.create_user(user_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/users/#{user}")
      |> render(:show, user: user)
    end
  end

  # GET /api/v1/users/:id  (admin ou o próprio usuário)
  def show(conn, %{"id" => id}) do
    current = Guardian.Plug.current_resource(conn)

    cond do
      current.role == "admin" ->
        user = Accounts.get_user!(id)
        json(conn, Map.take(user, [:id, :name, :email, :phone]))

      Integer.to_string(current.id) == id ->
        json(conn, Map.take(current, [:id, :name, :email, :phone]))

      true ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Forbidden"})
    end
  end

  # PUT /api/v1/users/:id
  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user!(id)

    with {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
      render(conn, :show, user: user)
    end
  end

  # DELETE /api/v1/users/:id
  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)

    with {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end
end
