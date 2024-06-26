defmodule CellularAutomata.World.Supervisor do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    children = [
      {CellularAutomata.World, []},
      {CellularAutomata.Cell.Supervisor, []},
      {Registry, keys: :unique, name: CellularAutomata.Cell.Registry}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
