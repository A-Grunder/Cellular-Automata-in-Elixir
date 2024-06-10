defmodule Cell.Supervisor do
  use DynamicSupervisor

  def start_link do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_cell({position, init_cell_state}) do
    DynamicSupervisor.start_child(__MODULE__, {Cell, {position, init_cell_state}})
  end

  def get_all_cells do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(&elem(&1, 1))
  end

end
