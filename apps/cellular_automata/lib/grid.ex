defmodule Grid do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
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
    Enum.reduce(responses, {%{}, %{}}, fn {pos, state, new_cells}, {acc_states, acc_cells} ->
        {Map.put(acc_states, pos, state), Map.merge(acc_cells, new_cells)}
      end)
  end

  defp call_for_update_and_start({current_states, new_cells}) do
    new = Enum.map(new_cells, fn {pos, state} ->
      Task.async(fn -> Cell.start({pos, state}) end)
    end)
    current = Enum.map(current_states, fn {pos, state} ->
      Task.async(fn -> Cell.update_state(state) end)
    end)

  end
end
