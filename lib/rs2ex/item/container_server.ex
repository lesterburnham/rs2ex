defmodule Rs2ex.Item.ContainerServer do
  alias Rs2ex.Item.Container

  defstruct [:always_stack, :capacity, items: [], hooks: []]

  def start_link do
    # todo: change this to have unique names
    Agent.start_link(fn -> %__MODULE__{always_stack: false, capacity: 28} end, name: __MODULE__)
  end

  def add_item(id, quantity), do: container_function(&Container.add_item/4, binding())

  def swap(from_slot, to_slot), do: container_function(&Container.swap/4, binding())

  defp container_function(fun, args) do
    Agent.get_and_update(__MODULE__, fn state ->
      opts = %{
        always_stack: state.always_stack,
        capacity: state.capacity
      }

      {_, items} = ret = apply(fun, [state.items] ++ Keyword.values(args) ++ [opts])

      {ret, %__MODULE__{state | items: items}}
    end)
  end

  def get_items do
    Agent.get(__MODULE__, fn state -> state.items end)
  end
end
