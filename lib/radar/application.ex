defmodule Radar.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Cluster.Supervisor, [Application.get_env(:libcluster, :topologies), [name: MyApp.ClusterSupervisor]]},
      Radar.Cache,
      # {Radar.Services.RateLimit, %{}},
      RadarWeb.Telemetry,
      Radar.Repo,
      {Phoenix.PubSub, name: Radar.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Radar.Finch},
      # Start a worker by calling: Radar.Worker.start_link(arg)
      # {Radar.Worker, arg},
      # Start to serve requests, typically the last entry
      RadarWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Radar.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RadarWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
