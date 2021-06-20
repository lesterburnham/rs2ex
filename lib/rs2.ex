defmodule RS2 do
  use Application

  def start(_type, _args) do
    children = [
      RS2.Server,
      RS2.World,
      RS2.Tick,
      Registry.child_spec(keys: :unique, name: RS2.Container.Registry),
      {DynamicSupervisor, strategy: :one_for_one, name: RS2.Container.Supervisor},
      Registry.child_spec(keys: :unique, name: RS2.Xyz)
    ]

    opts = [strategy: :one_for_one, name: RS2.Application]
    Supervisor.start_link(children, opts)
  end
end
