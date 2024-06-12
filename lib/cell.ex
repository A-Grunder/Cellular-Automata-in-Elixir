defmodule CellularAutomata.Cell do
  @moduledoc """
  Represents a cell in a cellular automata.

  A cell has a state, which is represented by an integer. For example, if the
  automata has two states, the cell can be either 0 or 1, and if it has three
  states, the cell can be 0, 1, or 2.

  The cell also has a position, which is represented by a tuple of integers. On
  a two-dimensional grid, the position can be represented as {x, y}.

  Since we can't have an infinite number of processes, the absence of a cell at
  a given position represents a cell with a default state, generally 0.
  """

  use GenServer

  require Logger

  @default_state 0

  # Number of states the cell can have (for example, 2 in the Game of Life)
  @num_states 2

  # Moore neighbourhood
  @neighbourhoud [
    {-1, -1}, {0, -1}, {1, -1},
    {-1,  0},          {1,  0},
    {-1,  1}, {0,  1}, {1,  1}
  ]

  # alternative neighbourhood (von Neumann neighbourhood)
  #@neighbourhoud [ {0, -1}, {0, 1}, {-1, 0}, {1, 0} ]

  ##############
  # Init/Start #
  ##############

  def start_link({position, init_cell_state}) do
    GenServer.start_link(__MODULE__, {position, init_cell_state}, name: via_registry(position))
  end

  @impl true
  def init({position, init_cell_state}) do
    Registry.register(CellularAutomata.Cell.Registry, position, init_cell_state)
    {:ok, %{position: position, state: init_cell_state, next_state: init_cell_state}}
  end

  ##############
  # Public API #
  ##############

  @doc """
  Stops the given cell process.
  """
  def stop_process(process) do
    Registry.unregister(CellularAutomata.Cell.Registry, process)
    CellularAutomata.Cell.Supervisor.stop_process(process)
  end

  @doc """
  Starts the cell process at the given position, with the given initial state.
  """
  def new_cell({position, init_cell_state}) do
    CellularAutomata.Cell.Supervisor.start_cell({position, init_cell_state})
  end

  @doc """
  Sets the state of the cell at the given position.
  """
  def set_state(position, state) do
    GenServer.call(via_registry(position), {:set_state, state})
  end

  @doc """
  Call for the cell to calculate its next state.
  """
  def get_next_state(process) do
    GenServer.call(process, :get_next_state)
  end

  @doc """
  Call for the cell to update its state.
  """
  def update_state(process) do
    GenServer.call(process, :update_state)
  end

  @doc """
  Get a tuple with the position and state of the cell.
  """
  def info(process) do
    GenServer.call(process, :info)
  end

  @doc """
  Get the state of the cell at the given position, or nil if there is no cell
  """
  def get_state(position) do
    case Registry.lookup(CellularAutomata.Cell.Registry, position) do
      [] -> nil
      [{_, state}] -> state
    end
  end


  ###############
  # Private API #
  ###############

  defp via_registry(position) do
    {:via, Registry, {CellularAutomata.Cell.Registry, position}}
  end

  defp get_neighbours_positions(position, neighbourhood) do
    Enum.map(neighbourhood, fn neighbour ->
      Enum.zip(position, neighbour)
      |> Enum.map(fn {coord, offset} -> coord + offset end)
    end)
  end

  defp get_neighbours_states(position, neighbourhoud) do
    neighbours = get_neighbours_positions(position, neighbourhoud)

    # use get_state to get the state of each neighbour
    Enum.reduce(neighbours, List.duplicate(0, @num_states), fn neighbour, acc ->
      case get_state(neighbour) do
        nil -> List.update_at(acc, @default_state, &(&1 + 1))
        state -> List.update_at(acc, state, &(&1 + 1))
      end
    end)
  end

  defp calculate_next_state(state, surrounding_states) do
    # Simple Game of Life rules
    case {state, surrounding_states} do
      {1, [6, 2]} -> 1
      {_, [5, 3]} -> 1
      {_, _} -> 0
    end

    # Alternative rules ()
  end

  #############
  # Callbacks #
  #############

  @impl true
  def handle_call(:get_next_state, _from, cell_state) do

    surrounding_states = get_neighbours_states(cell_state.position, @neighbourhoud)
    next_state = calculate_next_state(cell_state.state, surrounding_states)

    {:reply,{self(), cell_state.position, next_state}, %{cell_state | next_state: next_state}}
  end

  @impl true
  def handle_call(:update_state, _from, cell_state) do
    new_cell_state = %{cell_state | state: cell_state.next_state}
    Registry.update_value(Cell.Registry, cell_state.position, new_cell_state.state)
    {:reply, :ok, new_cell_state}
  end

  @impl true
  def handle_call({:set_state, state}, _from, cell_state) do
    new_cell_state = %{cell_state | state: state}
    Registry.update_value(Cell.Registry, cell_state.position, new_cell_state.state)
    {:reply, :ok, new_cell_state}
  end

  @impl true
  def handle_call(:info, _from, cell_state) do
    {:reply, {cell_state.position, cell_state.state}, cell_state}
  end
end
