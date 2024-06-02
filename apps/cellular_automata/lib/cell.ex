defmodule Cell do
  @moduledoc """
  Represents a cell in a cellular automata.

  A cell has a state, which is represented by an integer. For example, if the
  automata has two states, the cell can be either 0 or 1, and if it has three
  states, the cell can be 0, 1, or 2.

  The cell also has a position, which is represented by a tuple of integers. On
  a two-dimensional grid, the position can be represented as {x, y}.

  Since the grid can be infinite, a cell in a state of "0" can be represented by
  the absence of a cell in the grid. This is useful for optimization purposes.
  To do this we terminate the process representing a cell in state "0"
  surrounded by other cells in state "0".
  """

  use GenServer

  

end
