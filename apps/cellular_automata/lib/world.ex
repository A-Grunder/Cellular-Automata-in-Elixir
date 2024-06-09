defmodule World do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  def tick do
    GenServer.call(__MODULE__, :tick)
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
    # Turn all responses in form {pid, pos, state, %{pos => state}} into
    # {[pid], [pid], %{pos => state}, %{pos => state}}. A response is a tuple with the
    # pid of the cell, the position of the cell, the next state of the cell, and
    # a map of cells with their next state that must be created. The first two lists
    # are the pids and the states of the cells that must be updated, and those that
    # must be deleted respectively. The third is a map of current cells with their
    # next state, and the fourth is a map of new cells that must be created.
    responses
    |> Enum.reduce({[], [], %{}, %{}}, fn
      {pid, _pos, -1, new_cells}, {update_pids, delete_pids, update_states, new_cells_acc} ->
        {update_pids, [pid | delete_pids], update_states, Map.merge(new_cells, new_cells_acc)}
      {pid, pos, state, new_cells}, {update_pids, delete_pids, update_states, new_cells_acc} ->
        {[pid | update_pids], delete_pids, Map.put(update_states, pos, state), Map.merge(new_cells, new_cells_acc)}
    end)
  end

  defp update_cells({update_pids, delete_pids, states, new_cells}) do
    new_cells
    |> Enum.map(fn {pos, state} -> Task.async(fn -> Cell.new_cell({pos, state}) end) end)
    |> Enum.map(&Task.await/1)

    delete_pids
    |> Enum.map(fn pid -> Task.async(fn -> Cell.stop_process(pid) end) end)
    |> Enum.map(&Task.await/1)

    update_pids
    |> Enum.map(fn pid -> Task.async(fn -> Cell.update_state(pid) end) end)
    |> Enum.map(&Task.await/1)

    Map.merge(states, new_cells)
  end

  def handle_call(:tick, _from, []) do
    answer = get_all_cells()
    |> call_for_next_state()
    |> reduce_responses()
    |> update_cells()

    {:reply, answer, []}
  end
end
