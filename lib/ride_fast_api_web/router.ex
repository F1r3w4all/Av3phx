defmodule RideFastApiWeb.Router do
  use RideFastApiWeb, :router

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

  scope "/", RideFastApiWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/api/v1", RideFastApiWeb do
  pipe_through :api # Todas as rotas dentro deste scope usarão o pipeline :api

  # Escopo específico para autenticação
  scope "/auth" do
    # 1. Registro (Endpoint que fizemos na última interação)
    post "/register", AuthController, :register

    # 2. Login (POST /api/v1/auth/login)
    post "/login", AuthController, :login
  end

  # Mais tarde, você colocará rotas protegidas como /users e /rides aqui
end

  # Other scopes may use custom stacks.
  # scope "/api", RideFastApiWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:ride_fast_api, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: RideFastApiWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
