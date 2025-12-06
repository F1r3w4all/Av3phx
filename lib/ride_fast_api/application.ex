defmodule RideFastApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RideFastApiWeb.Telemetry,
      RideFastApi.Repo,
      {DNSCluster, query: Application.get_env(:ride_fast_api, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: RideFastApi.PubSub},
      # Start a worker by calling: RideFastApi.Worker.start_link(arg)
      # {RideFastApi.Worker, arg},
      # Start to serve requests, typically the last entry
      RideFastApiWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RideFastApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RideFastApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
