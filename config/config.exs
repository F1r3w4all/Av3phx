import Config

# Configuração geral
config :ride_fast_api,
  ecto_repos: [RideFastApi.Repo],
  generators: [timestamp_type: :utc_datetime]

# Endpoint
config :ride_fast_api, RideFastApiWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: RideFastApiWeb.ErrorHTML, json: RideFastApiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: RideFastApi.PubSub,
  live_view: [signing_salt: "l/ArBiMh"]

# Guardian – DEV (pode ajustar depois para usar variável de ambiente)
config :ride_fast_api, RideFastApi.Guardian,
  issuer: "ride_fast_api",
  secret_key: System.get_env("GUARDIAN_SECRET") || "DEV_SECRET_CHANGE_ME"

# Mailer
config :ride_fast_api, RideFastApi.Mailer, adapter: Swoosh.Adapters.Local

# Esbuild
config :esbuild,
  version: "0.25.4",
  ride_fast_api: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Tailwind
config :tailwind,
  version: "4.1.7",
  ride_fast_api: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# JSON
config :phoenix, :json_library, Jason

# Importa configs específicas de ambiente (dev.exs, prod.exs etc.)
import_config "#{config_env()}.exs"
