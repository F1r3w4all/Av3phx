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
  def login(conn, %{"email" => email, "password" => password} = _params) do
    # 1. Tenta autenticar (com Bcrypt)
    case Accounts.authenticate_user_or_driver(email, password) do
      # Autenticação Bcrypt bem-sucedida!
      {:ok, user_or_driver} ->
        # 2. Gerar o JWT (usando Guardian)
        case Guardian.issue(user_or_driver) do
          {:ok, jwt, _resource} ->
            # 3. Resposta de sucesso (200 OK)
            conn
            |> json(%{
              token: jwt,
              # O campo :role é inserido no Contexto e é crucial para o AuthZ futuro
              user: Map.take(user_or_driver, [:id, :name, :email, :role])
            })

          {:error, _reason} ->
            # Falha interna ao emitir o token
            conn
            |> put_status(:internal_server_error)
            |> json(%{error: "Falha ao gerar o token de segurança."})
        end

      # Falha na autenticação (email não encontrado ou senha incorreta)
      {:error, :unauthorized} ->
        # 401 Unauthorized (conforme o requisito)
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Credenciais inválidas."})

      _ ->
        # Outras falhas de Contexto
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Erro no servidor ao tentar login."})
    end
  end

  # Tratamento para JSON sem os campos obrigatórios
  def login(conn, %{"email" => email, "password" => password}) do
  with {:ok, user_or_driver} <- Accounts.authenticate_user_or_driver(email, password),
       {:ok, token, _claims} <- RideFastApi.Guardian.issue(user_or_driver) do
    json(conn, %{token: token})
  else
    _ -> conn |> put_status(:unauthorized) |> json(%{error: "Invalid credentials"})
  end
end
end
