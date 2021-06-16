defmodule Rs2ex.Item.ContainerServer do
  alias Rs2ex.Item.Container

  defstruct [:always_stack, :capacity, items: [], hooks: []]

  def start_link do
    # todo: change this to have unique names
    Agent.start_link(fn -> %__MODULE__{always_stack: false, capacity: 28} end, name: __MODULE__)
  end

  def add_item(id, quantity) do
    Agent.get_and_update(__MODULE__, fn state ->
      {_, items} =
        ret =
        Container.add_item(state.items, id, quantity, %{
          always_stack: state.always_stack,
          capacity: state.capacity
        })

      {ret, %__MODULE__{state | items: items}}
    end)
  end

  def get_items do
    Agent.get(__MODULE__, fn state -> state.items end)
  end
end
