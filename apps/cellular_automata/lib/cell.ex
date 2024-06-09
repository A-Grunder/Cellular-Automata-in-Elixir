defmodule Cell do
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

  @default_state 0

  @neighbourhoud [
    {-1, -1}, {0, -1}, {1, -1},
    {-1,  0},          {1,  0},
    {-1,  1}, {0,  1}, {1,  1}
  ]

  ##############
  # Init/Start #
  ##############

  def start_link({position, init_cell_state}) do
    GenServer.start_link(__MODULE__, {position, init_cell_state}, name: via_registry(position))
  end

  @impl true
  def init({position, init_cell_state}) do
    Registry.register(Cell.Registry, position, init_cell_state)
    {:ok, %{position: position, state: init_cell_state, next_state: init_cell_state}}
  end

  ##############
  # Public API #
  ##############

  @doc """
  Stops the given cell process.
  """
  def stop_process(process) do
    Registry.unregister(Cell.Registry, process)
    GenServer.stop(process)
    Supervisor.terminate_child(Cell.Supervisor, process)
  end

  @doc """
  Starts the cell process at the given position, with the given initial state.
  """
  def new_cell({position, init_cell_state}) do
    Supervisor.start_child(Cell.Supervisor, {position, init_cell_state})
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
  Get the state of the cell at the given position, or nil if there is no cell
  """
  def get_state(position) do
    case Registry.lookup(Cell.Registry, position) do
      [] -> nil
      [{_, state}] -> state
    end
  end


  ###############
  # Private API #
  ###############

  defp via_registry(position) do
    {:via, Registry, {Cell.Registry, position}}
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
    Enum.reduce(neighbours, {%{}, MapSet.new()}, fn neighbour, {acc_states, acc_nil} ->
      case get_state(neighbour) do
        nil -> {Map.update(acc_states, @default_state, 1, &(&1 + 1)), MapSet.put(acc_nil, neighbour)}
        state -> {Map.update(acc_states, state, 1, &(&1 + 1)), acc_nil}
      end
    end)
  end

  defp calculate_next_state(state, surrounding_states) do
    # Simple Game of Life rules
    case {state, surrounding_states} do
      {1, %{1 => 2}} -> 1
      {1, %{1 => 3}} -> 1
      {1, %{1 => _}} -> 0
      {0, %{1 => 3}} -> 1
      {0, %{1 => 0}} -> -1
      {0, %{1 => _}} -> 0
      {_, _} -> 0
    end
  end

  #############
  # Callbacks #
  #############

  @impl true
  def handle_call(:get_next_state, _from, cell_state) do

    # Get the states of the neighbours
    {surrounding_states, nils} = get_neighbours_states(cell_state.position, @neighbourhoud)

    # Calculate the next state
    next_state = calculate_next_state(cell_state.state, surrounding_states)

    # For each nil, get it's neighbours and calculate the next state, put it in a map if it's not the default state
    new_cells = MapSet.to_list(nils)
    |> Enum.map(fn nil_pos ->
      {surrounding_states, _} = get_neighbours_states(nil_pos, @neighbourhoud)
      {nil_pos, calculate_next_state(@default_state, surrounding_states)}
    end)
    |> Enum.filter(fn {_, state} -> state != @default_state end)
    |> Map.new()

    {:reply, {self(), cell_state.position, next_state, new_cells}, %{cell_state | next_state: next_state}}
  end

  @impl true
  def handle_call(:update_state, _from, cell_state) do
    new_cell_state = %{cell_state | state: cell_state.next_state}
    Registry.update_value(Cell.Registry, cell_state.position, new_cell_state.state)
    {:reply, :ok, new_cell_state}
  end
end
