defmodule CellularAutomata.Scene.Home do
  use Scenic.Scene
  require Logger

  import Scenic.Primitives
  import Scenic.Components

  alias Scenic.Graph
  alias CellularAutomata.World

  @cell_size 4
  @min -50
  @max 50
  @x_offset 60
  @y_offset 60
  @colors [:white, :black, :red, :green, :blue, :yellow, :cyan, :magenta]

  def init(scene, _param, _opts) do
    World.start_link(nil)
    World.start_state()

    graph = draw_graph(World.get_grid())

    scene = push_graph(scene, graph)
    {:ok, scene}
  end

  def handle_event({:click, :tick_button}, _context, scene) do
    scene = tick(scene)
    {:noreply, scene}
  end

  defp draw_graph(grid) do
    Graph.build()
    |> rect({(@max - @min) * @cell_size + @cell_size, (@max - @min ) * @cell_size+ @cell_size}, stroke: {2, :gray}, translate: {@x_offset, @y_offset})
    |> draw_grid(grid)
    |> button("Tick", id: :tick_button, translate: {10, 10})

  end

  defp tick(scene) do
    grid = World.tick()
    graph = draw_graph(grid)

    #Logger.info(grid)

    scene
    |> push_graph(graph)
  end

  defp draw_grid(graph, grid) do
    Enum.reduce(grid, graph, fn {{x, y}, state}, graph ->
      if x >= @min and x <= @max and y >= @min and y <= @max do
        color = Enum.at(@colors, state, :white)
        graph
        |> rect(
          {@cell_size, @cell_size},
          fill: color,
          translate: {
            ((x - @min) * @cell_size + @x_offset),
            ((y - @min) * @cell_size + @y_offset)
            }
          )
      else
        graph
      end
    end)
  end
end
