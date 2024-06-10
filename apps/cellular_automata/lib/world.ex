defmodule World do
  use GenServer

  @min -500
  @max 500

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    # Initialize the grid with cells
    for x <- @min..@max, y <- @min..@max do
      # Create a new cell at the given position, if its a glider gun cell, set it to 1
      if Pattern.is_glider_gun?(x, y, 50, 50), do: Cell.new_cell({{x, y}, 1}), else: Cell.new_cell({{x, y}, 0})
    end
    {:ok, %{}}
  end

  def tick do
    GenServer.call(__MODULE__, :tick)
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

  def handle_call(:tick, _from, []) do
    answer = get_all_cells()
    |> call_for_next_state()
    |> reduce_responses()
    |> update_cells()

    {:reply, answer, []}
  end

  def handle_call({:set_state, position, state}, _from, _) do
    Cell.set_state(position, state)
    {:reply, :ok, []}
  end
end
