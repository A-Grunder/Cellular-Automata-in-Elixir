defmodule Cell do
  @moduledoc """
  Represents a cell in a cellular automata.

  A cell has a state, which is represented by an integer. For example, if the
  automata has two states, the cell can be either 0 or 1, and if it has three
  states, the cell can be 0, 1, or 2.

  The cell also has a position, which is represented by a tuple of integers. On
  a two-dimensional grid, the position can be represented as {x, y}.

  Since we can't have an infinite number of processes, the absence of a cell at
  a given position represents a cell with a default state, generally 0. We
  """

  use GenServer

  ##############
  # Init/Start #
  ##############

  def start_link({position, init_cell_state}) do
    GenServer.start_link(__MODULE__, {position, init_cell_state}, name: {
      :via, Registry, {Cell.Registry, position}
    })
  end

  @impl true
  def init({position, init_cell_state}) do
    Registry.register(Cell.Registry, position, init_cell_state)
    {:ok, %{position: position, state: init_cell_state, next_state: nil}}
  end

  ##############
  # Public API #
  ##############

  @doc """
  Stops the cell process at the given position.
  """
  def stop_process_at(position) do
    # TODO
  end

  @doc """
  Stops the given cell process.
  """
  def stop_process(process) do
    # TODO
  end

  @doc """
  Starts the cell process at the given position, with the given initial state.
  """
  def start({position, init_cell_state}) do
    # TODO
  end

  @doc """
  Call for the cell to calculate its next state.
  """
  def get_next_state(process) do
    GenServer.call(process, :get_next_state)
  end

  @doc """
  Call for the cell at the given position to update its state to the given state.
  """
  def update_state(position, state) do
    GenServer.call({:via, Registry, {Cell.Registry, position}}, {:update_state, state})
  end

  @doc """
  Get the state of the cell at the given position, or nil if there is no cell
  """
  def get_state(position) do
    Registry.lookup(Cell.Registry, position)
    |> Enum.map(fn
      {_, state} -> state
      nil -> nil
    end)
  end
  

  ###############
  # Private API #
  ###############



  #############
  # Callbacks #
  #############


end
