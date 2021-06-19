defmodule Rs2ex.Item.ContainerServer do
  alias Rs2ex.Item.Container

  defstruct [:always_stack, :capacity, items: [], hooks: []]

  def start_link(hooks \\ []) do
    # todo: change this to have unique names
    Agent.start_link(
      fn ->
        %__MODULE__{
          always_stack: false,
          capacity: 28,
          items: List.duplicate(nil, 28),
          hooks: hooks
        }
      end,
      name: __MODULE__
    )
  end

  # if we add pid to this we'll need to make sure the args uses
  # Keyword.drop to remove 'pid' from the container_function calls

  def add_item(id, quantity) do
    container_function(&Container.add_item/4, binding())
    |> after_container_function_hooks(:handle_container_update)
  end

  def swap(from_slot, to_slot) do
    container_function(&Container.swap/4, binding())
    |> after_container_function_hooks(:handle_slot_swap, [from_slot, to_slot])
  end

  def set(slot, id, quantity) do
    container_function(&Container.set/5, binding())
    |> after_container_function_hooks(:handle_slot_set, [slot])
  end

  def insert(from_slot, to_slot) do
    container_function(&Container.insert/4, binding())
    |> after_container_function_hooks(:handle_container_update)
  end

  defp container_function(fun, args) do
    Agent.get_and_update(__MODULE__, fn state ->
      opts = %{
        always_stack: state.always_stack,
        capacity: state.capacity,
        hooks: state.hooks
      }

      {_, items} = ret = apply(fun, [state.items] ++ Keyword.values(args) ++ [opts])

      {ret, %__MODULE__{state | items: items}}
    end)
  end

  defp after_container_function_hooks(ret, fun, extra_args \\ []) do
    case ret do
      {:ok, items} ->
        run_hooks(fun, [items] ++ extra_args)
        ret

      _ ->
        ret
    end
  end

  defp run_hooks(fun, args) do
    Enum.each(get_hooks(), &apply(&1, fun, args))
  end

  defp get_hooks do
    Agent.get(__MODULE__, fn state -> state.hooks end)
  end

  def get_items do
    Agent.get(__MODULE__, fn state -> state.items end)
  end
end
