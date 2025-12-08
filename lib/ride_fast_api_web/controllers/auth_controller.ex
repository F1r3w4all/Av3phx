defmodule RideFastApiWeb.AuthController do
  use RideFastApiWeb, :controller

  # Alias para o Contexto (onde está a lógica de Bcrypt e criação)
  alias RideFastApi.Accounts
  # Alias para o nosso módulo Guardian (onde está a emissão de JWT)
  alias RideFastApi.Guardian
  alias Ecto.Changeset
  # --- 1. POST /api/v1/auth/register ---

  @doc "Registra um novo User ou Driver."
  def register(conn, params) do
    case Map.get(params, "role") do
      role when role in ["user", "admin"] ->
        case Accounts.create_user(params) do
          {:ok, user} ->
            conn
            |> put_status(:created)
            |> json(Map.take(user, [:id, :name, :email, :role]))

          {:error, %Ecto.Changeset{} = changeset} ->
            errors =
              Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)

            conn
            |> put_status(:bad_request)
            |> json(%{errors: errors})

          {:error, %{result: :already_exists}} ->
            conn
            |> put_status(:conflict)
            |> json(%{error: "E-mail já cadastrado."})

          _ ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{error: "Erro inesperado ao criar usuário."})
        end

      "driver" ->
        case Accounts.create_driver(params) do
          {:ok, driver} ->
            conn
            |> put_status(:created)
            |> json(Map.take(driver, [:id, :name, :email]))

          {:error, %{result: :already_exists}} ->
            conn
            |> put_status(:conflict)
            |> json(%{error: "E-mail de motorista já cadastrado."})

          {:error, %{errors: errors}} ->
            conn
            |> put_status(:bad_request)
            |> json(%{errors: errors})

          _ ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{error: "Erro inesperado ao criar motorista."})
        end

      _ ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "A 'role' deve ser 'user' ou 'driver'."})
    end
  end

  # --- 2. POST /api/v1/auth/login ---

  @doc "Autentica e retorna JWT."
  def login(conn, %{"email" => email, "password" => password}) do
    with {:ok, user_or_driver} <- Accounts.authenticate_user_or_driver(email, password),
         {:ok, token, _claims} <- Guardian.issue(user_or_driver) do
      conn
      |> put_status(:ok)
      |> json(%{
        token: token,
        user: Map.take(user_or_driver, [:id, :name, :email, :role])
      })
    else
      {:error, :unauthorized} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Credenciais inválidas."})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Falha ao gerar o token de segurança.", reason: inspect(reason)})

      _ ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Erro no servidor ao tentar login."})
    end
  end
end
