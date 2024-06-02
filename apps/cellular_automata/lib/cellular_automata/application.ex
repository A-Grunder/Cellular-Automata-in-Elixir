defmodule CellularAutomata.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {DNSCluster, query: Application.get_env(:cellular_automata, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: CellularAutomata.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: CellularAutomata.Finch}
      # Start a worker by calling: CellularAutomata.Worker.start_link(arg)
      # {CellularAutomata.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: CellularAutomata.Supervisor)
  end
end
