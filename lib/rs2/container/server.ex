defmodule RS2.Container.Server do
  alias RS2.Container

  defstruct [:always_stack, :capacity, items: [], hooks: []]

  def start_link(container_id, capacity, always_stack, hooks) do
    Agent.start_link(
      fn ->
        %__MODULE__{
          always_stack: always_stack,
          capacity: capacity,
          items: List.duplicate(nil, capacity),
          hooks: hooks
        }
      end,
      name: via_tuple(container_id)
    )
  end

  defp via_tuple(container_id), do: {:via, Registry, {RS2.Container.Registry, container_id}}

  def add_item(container_id, id, quantity) do
    container_function(container_id, &Container.add_item/4, binding())
    |> after_container_function_hooks(container_id, :handle_container_update)
  end

  def swap_item(container_id, from_slot, to_slot) do
    container_function(container_id, &Container.swap_item/4, binding())
    |> after_container_function_hooks(container_id, :handle_slot_swap, [from_slot, to_slot])
  end

  def set_item(container_id, slot, nil) do
    container_function(container_id, &Container.set_item/4, binding())
    |> after_container_function_hooks(container_id, :handle_slot_set, [slot])
  end

  def set_item(container_id, slot, id, quantity) do
    container_function(container_id, &Container.set_item/5, binding())
    |> after_container_function_hooks(container_id, :handle_slot_set, [slot])
  end

  def insert(container_id, from_slot, to_slot) do
    container_function(container_id, &Container.insert/4, binding())
    |> after_container_function_hooks(container_id, :handle_container_update)
  end

  def remove_item(container_id, id, quantity) do
    container_function(container_id, &Container.remove_item/4, binding())
    |> after_container_function_hooks(container_id, :handle_slot_set)
  end

  def remove_item(container_id, id, quantity, preferred_slot) do
    container_function(container_id, &Container.remove_item/5, binding())
    |> after_container_function_hooks(container_id, :handle_slot_set)
  end

  def clear_items(container_id) do
    container_function(container_id, &Container.clear_items/2, binding())
    |> after_container_function_hooks(container_id, :handle_container_update)
  end

  def transfer_item(_from_container_id, _to_container_id, _from_slot, _id) do
    # RS2.Container.Server.transfer_item({"mopar", :inventory}, {"mopar", :equipment}, 0, 4151, 1)

    # from_items = get_items(from_container_id)
    # # todo how to get???
    # from_opts = nil
    # to_items = get_items(to_container_id)
    # # todo how to get???
    # to_opts = nil

    # container_function(container_id, &Container.transfer_item/2, binding())
    # |> after_container_function_hooks(container_id, :handle_container_update)
  end

  defp container_function(container_id, fun, args) do
    Agent.get_and_update(via_tuple(container_id), fn state ->
      opts = %{
        always_stack: state.always_stack,
        capacity: state.capacity,
        hooks: state.hooks
      }

      ret =
        apply(
          fun,
          [state.items] ++ (args |> remove_container_id_arg() |> Keyword.values()) ++ [opts]
        )

      case ret do
        {_, items} ->
          {ret, %__MODULE__{state | items: items}}

        {_, items, _, _} ->
          {ret, %__MODULE__{state | items: items}}
      end
    end)
  end

  defp remove_container_id_arg(args) do
    args |> Keyword.drop([:container_id])
  end

  defp after_container_function_hooks(ret, container_id, fun, extra_args \\ []) do
    case ret do
      {:ok, items} ->
        run_hooks(container_id, fun, [items] ++ extra_args)
        ret

      {:ok, items, slots, _} ->
        Enum.each(slots, fn slot ->
          run_hooks(container_id, fun, [items] ++ [slot])
        end)

        ret

      _ ->
        ret
    end
  end

  def has_room_for?(container_id, id, quantity) do
    Agent.get(via_tuple(container_id), fn state ->
      opts = %{
        always_stack: state.always_stack,
        capacity: state.capacity,
        hooks: state.hooks
      }

      Container.has_room_for?(state.items, id, quantity, opts)
    end)
  end

  defp run_hooks(container_id, fun, args) do
    {session, _} = container_id

    Enum.each(get_hooks(container_id), fn {mod, config} ->
      apply(mod, fun, [session] ++ args ++ [config])
    end)
  end

  defp get_hooks(container_id) do
    Agent.get(via_tuple(container_id), fn state -> state.hooks end)
  end

  def get_items(container_id) do
    Agent.get(via_tuple(container_id), fn state -> state.items end)
  end
end
