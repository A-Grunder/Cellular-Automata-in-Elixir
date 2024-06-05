defmodule Grid.Supervisor do
  use Supervisor

  def start(_type, _args) do
    start_link()
  end

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_args) do
    children = [
      %{
        id: Grid,
        start: {Grid, :start_link, []},
        restart: :transient,
        type: :worker
      },
      %{
        id: Cell.Supervisor,
        start: {Cell.Supervisor, :start_link, []},
        restart: :transient,
        type: :supervisor
      },
      %{
        id: Registry,
        start: {Registry, :start_link, [Registry, keys: :unique, name: Cell.Registry]},
        restart: :transient,
        type: :supervisor
      }
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
