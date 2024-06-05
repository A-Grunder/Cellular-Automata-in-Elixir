defmodule Cell.Supervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Cell, []}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end

  def get_all_cells do
    Cell.Supervisor
    |> Supervisor.which_children
    |> Enum.map(&elem(&1, 1))
  end

end
