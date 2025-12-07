defmodule RideFastApiWeb.Router do
  use RideFastApiWeb, :router

  import Phoenix.Controller
  alias RideFastApiWeb.AuthErrorHandler
  alias RideFastApiWeb.Plugs.AuthorizeAdmin

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {RideFastApiWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end
  pipeline :authorize_admin do
    plug AuthorizeAdmin
  end

  # Pipeline de autenticação com Guardian para APIs
  pipeline :api_auth do
    plug Guardian.Plug.Pipeline,
      module: RideFastApi.Guardian,
      error_handler: RideFastApiWeb.AuthErrorHandler

    plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
    plug Guardian.Plug.EnsureAuthenticated
    plug Guardian.Plug.LoadResource
  end

  scope "/", RideFastApiWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Rotas públicas da API (registro e login)
  scope "/api/v1", RideFastApiWeb do
    pipe_through :api

    post "/auth/register", AuthController, :register
    post "/auth/login", AuthController, :login
  end

  # Rotas protegidas da API (users)
 pipeline :api_auth do
  plug Guardian.Plug.Pipeline,
    module: RideFastApi.Guardian,
    error_handler: RideFastApiWeb.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end

scope "/api/v1", RideFastApiWeb do
  pipe_through [:api, :api_auth, :authorize_admin]

  get "/users", UserController, :index
  get "/users/:id", UserController, :show
  put "/users/:id", UserController, :update
  delete "/users/:id", UserController, :delete
end

  scope "/api/v1", RideFastApiWeb do
    pipe_through [:api, :api_auth] # Apenas autenticação JWT é exigida

    # NOVO ENDPOINT DE LISTAGEM DE DRIVERS
    get "/drivers", DriverController, :index
    get "/drivers/:id", DriverController, :show
    post "/drivers", DriverController, :create
    put  "/drivers/:id", DriverController, :update
    delete "/drivers/:id", DriverController, :delete
    get "/drivers/:driver_id/profile", DriverController, :profile
    post "/drivers/:driver_id/profile", DriverController, :create_profile
    put  "/drivers/:driver_id/profile",  DriverController, :update_profile
    post "/drivers/:driver_id/vehicles", DriverController, :create_vehicle
  end
end
