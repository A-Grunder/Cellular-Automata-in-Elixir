defmodule CellularAutomata.World do
  use GenServer

  alias CellularAutomata.Cell
  alias CellularAutomata.Pattern

  @min -100
  @max 100

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  def get_grid do
    GenServer.call(__MODULE__, :get_grid)
  end

  def tick do
    GenServer.call(__MODULE__, :tick)
  end

  def start_state do
    GenServer.call(__MODULE__, :start_state)
  end

  def set_state(position, state) do
    GenServer.call(__MODULE__, {:set_state, position, state})
  end

  defp get_all_cells do
    Cell.Supervisor.get_all_cells
  end

  defp call_for_next_state(cells) do
    cells
    |> Enum.map(&(Task.async(fn -> Cell.get_next_state(&1) end)))
    |> Enum.map(&Task.await/1)
  end

  defp reduce_responses(responses) do
    Enum.reduce(responses, {[],%{}}, fn {pid, pos, state}, {update_pids, board} ->
      {[pid | update_pids], Map.put(board, pos, state)}
    end)
  end

  defp update_cells({pids, board}) do
    pids
    |> Enum.map(&(Task.async(fn -> Cell.update_state(&1) end)))
    |> Enum.map(&Task.await/1)

    board
  end

  def handle_call(:tick, _from, state) do
    answer = get_all_cells()
    |> call_for_next_state()
    |> reduce_responses()
    |> update_cells()

    {:reply, answer, state}
  end

  def handle_call({:set_state, position, state}, _from, _) do
    Cell.set_state(position, state)
    {:reply, :ok, []}
  end

  def handle_call(:get_grid, _from, state) do
    response = Cell.Supervisor.get_all_cells_positions_and_states()
    |> Enum.reduce(%{}, fn {pos, state}, acc -> Map.put(acc, pos, state) end)

    {:reply, response, state}
  end

  def handle_call(:start_state, _from, state) do
    # Initialize the grid with cells
    for x <- @min..@max, y <- @min..@max do
      # Create a new cell at the given position, if its a glider gun cell, set it to 1
      if Pattern.is_glider_gun?(x, y, 30, 30), do: Cell.new_cell({{x, y}, 1}), else: Cell.new_cell({{x, y}, 0})
    end

    {:reply, :ok, state}
  end

end
