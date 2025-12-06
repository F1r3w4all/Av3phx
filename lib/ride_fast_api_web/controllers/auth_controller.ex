defmodule RideFastApiWeb.AuthController do
  use RideFastApiWeb, :controller

  # Alias para o Contexto (onde está a lógica de Bcrypt e criação)
  alias RideFastApi.Accounts
  # Alias para o nosso módulo Guardian (onde está a emissão de JWT)
  alias RideFastApi.Guardian

  # --- 1. POST /api/v1/auth/register ---

  @doc "Registra um novo User ou Driver."
  def register(conn, params) do
    # O corpo esperado inclui "role", "name", "email", "phone" e "password"
    case Map.get(params, "role") do
      "user" ->
        # Delega a criação (com Bcrypt) ao Contexto de Accounts
        case Accounts.create_user(params) do
          {:ok, user} ->
            # 201 Created com as informações do novo User
            conn
            |> put_status(:created)
            |> json(Map.take(user, [:id, :name, :email]))

          {:error, %{errors: errors}} ->
            # Tratamento de erros de validação (ex: campos inválidos, senha fraca)
            conn
            |> put_status(:bad_request)
            |> json(%{errors: errors})

          {:error, %{result: :already_exists}} ->
            # 409 Conflict (e-mail já cadastrado, decorrente do unique_constraint)
            conn
            |> put_status(:conflict)
            |> json(%{error: "E-mail já cadastrado."})

          _ ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{error: "Erro inesperado ao criar usuário."})
        end

      "driver" ->
        # Delega a criação (com Bcrypt) ao Contexto de Accounts
        case Accounts.create_driver(params) do
          {:ok, driver} ->
            # 201 Created com as informações do novo Driver
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
        # 400 Bad Request: 'role' inválida ou ausente
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
  def login(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "É necessário fornecer email e password."})
  end
end
