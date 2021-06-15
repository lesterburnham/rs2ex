defmodule Rs2ex do
  use Application

  def start(_type, _args) do
    children = [
      Rs2ex.Server,
      Rs2ex.World,
      Rs2ex.Tick,
      Registry.child_spec(
        keys: :unique,
        name: Rs2ex.Xyz
      )
    ]

    opts = [strategy: :one_for_one, name: Rs2ex.Application]
    Supervisor.start_link(children, opts)
  end
end
