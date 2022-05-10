defmodule Taxon.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Taxon.Fetcher.add_cloud_ips()

    children = [
      # Start the Ecto repository
      Taxon.Repo,
      # Start the Telemetry supervisor
      TaxonWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Taxon.PubSub},
      # Start the Endpoint (http/https)
      TaxonWeb.Endpoint
      # Start a worker by calling: Taxon.Worker.start_link(arg)
      # {Taxon.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Taxon.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TaxonWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
