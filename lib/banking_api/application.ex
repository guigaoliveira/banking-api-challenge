defmodule BankingApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      BankingApi.Repo,
      # Start the Telemetry supervisor
      BankingApiWeb.Telemetry,
      # Start the Endpoint (http/https)
      BankingApiWeb.Endpoint
      # Start a worker by calling: BankingApi.Worker.start_link(arg)
      # {BankingApi.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BankingApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BankingApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
