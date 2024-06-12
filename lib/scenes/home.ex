defmodule CellularAutomata.Scene.Home do
  use Scenic.Scene
  require Logger

  import Scenic.Primitives
  import Scenic.Components

  alias Scenic.Graph
  alias CellularAutomata.World

  @cell_size 1
  @min -250
  @max 250
  @x_offset 60
  @y_offset 60
  @colors [:white, :black, :red, :green, :blue, :yellow, :cyan, :magenta]

  def init(scene, _param, _opts) do
    World.start_link(nil)
    World.start_state()

    graph =
      Graph.build()
      |> rect({@max - @min, @max - @min}, stroke: {1, :white}, translate: {@x_offset, @y_offset})
      |> draw_grid(World.get_grid())
      |> button("Tick", id: :tick_button, translate: {10, 10})


    scene =
      scene
      |> push_graph(graph)
    {:ok, scene}
  end

  def handle_event({:click, :tick_button}, _context, scene) do
    scene = tick(scene)
    {:noreply, scene}
  end

  defp tick(scene) do
    grid = World.tick()
    graph =
      Graph.build()
      |> rect({@max - @min, @max - @min}, stroke: {1, :white}, translate: {@x_offset, @y_offset})
      |> draw_grid(grid)
      |> button("Tick", id: :tick_button, translate: {10, 10})

    #Logger.info(grid)

    scene
    |> push_graph(graph)
  end

  defp draw_grid(graph, grid) do
    Enum.reduce(grid, graph, fn {{x, y}, state}, graph ->
      if x > @min and x < @max and y > @min and y < @max do
        color = Enum.at(@colors, state, :white)
        graph
        |> rect({@cell_size, @cell_size}, fill: color, translate: {x - @min + @x_offset, y - @min + @y_offset})
      else
        graph
      end
    end)
  end
end
