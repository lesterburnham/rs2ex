defmodule RS2.Container.Server do
  alias RS2.Container

  defstruct [:always_stack, :capacity, items: [], hooks: [], session: "mopar"]

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

  def swap_item(from_slot, to_slot) do
    container_function(&Container.swap_item/4, binding())
    |> after_container_function_hooks(:handle_slot_swap, [from_slot, to_slot])
  end

  def set_item(slot, nil) do
    container_function(&Container.set_item/4, binding())
    |> after_container_function_hooks(:handle_slot_set, [slot])
  end

  def set_item(slot, id, quantity) do
    container_function(&Container.set_item/5, binding())
    |> after_container_function_hooks(:handle_slot_set, [slot])
  end

  def insert(from_slot, to_slot) do
    container_function(&Container.insert/4, binding())
    |> after_container_function_hooks(:handle_container_update)
  end

  def remove_item(id, quantity) do
    container_function(&Container.remove_item/4, binding())
    |> after_container_function_hooks(:handle_slot_set)
  end

  def remove_item(id, quantity, preferred_slot) do
    container_function(&Container.remove_item/5, binding())
    |> after_container_function_hooks(:handle_slot_set)
  end

  def clear_items() do
    container_function(&Container.clear_items/2, binding())
    |> after_container_function_hooks(:handle_container_update)
  end

  defp container_function(fun, args) do
    Agent.get_and_update(__MODULE__, fn state ->
      opts = %{
        always_stack: state.always_stack,
        capacity: state.capacity,
        hooks: state.hooks
      }

      ret = apply(fun, [state.items] ++ Keyword.values(args) ++ [opts])

      case ret do
        {_, items} ->
          {ret, %__MODULE__{state | items: items}}

        {_, items, _, _} ->
          {ret, %__MODULE__{state | items: items}}
      end
    end)
  end

  defp after_container_function_hooks(ret, fun, extra_args \\ []) do
    session = get_session()

    case ret do
      {:ok, items} ->
        run_hooks(fun, [session] ++ [items] ++ extra_args)
        ret

      {:ok, items, slots, _} ->
        Enum.each(slots, fn slot ->
          run_hooks(fun, [session] ++ [items] ++ [slot])
        end)

        ret

      _ ->
        ret
    end
  end

  def has_room_for?(id, quantity) do
    Agent.get(__MODULE__, fn state ->
      opts = %{
        always_stack: state.always_stack,
        capacity: state.capacity,
        hooks: state.hooks
      }

      Container.has_room_for?(state.items, id, quantity, opts)
    end)
  end

  defp run_hooks(fun, args) do
    Enum.each(get_hooks(), &apply(&1, fun, args))
  end

  defp get_hooks do
    Agent.get(__MODULE__, fn state -> state.hooks end)
  end

  defp get_session do
    Agent.get(__MODULE__, fn state -> state.session end)
  end

  def get_items do
    Agent.get(__MODULE__, fn state -> state.items end)
  end
end
