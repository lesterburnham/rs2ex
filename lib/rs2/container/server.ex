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

  def transfer_item(from_container_id, to_container_id, from_slot, id) do
    with {status, _new_from_items, new_to_items} <-
           Agent.get_and_update(via_tuple(to_container_id), fn to_state ->
             with {status, new_from_items, new_to_items} = ret <-
                    Agent.get_and_update(via_tuple(from_container_id), fn from_state ->
                      {_status, new_from_items, _new_to_items} =
                        ret =
                        Container.transfer_item(
                          from_state.items,
                          get_opts_for_state(from_state),
                          to_state.items,
                          get_opts_for_state(to_state),
                          from_slot,
                          id
                        )

                      {ret, %__MODULE__{from_state | items: new_from_items}}
                    end),
                  from_item_tuple <- {status, new_from_items} do
               after_container_function_hooks(
                 from_item_tuple,
                 from_container_id,
                 :handle_container_update
               )

               {ret, %__MODULE__{to_state | items: new_to_items}}
             end
           end),
         to_item_tuple <- {status, new_to_items} do
      after_container_function_hooks(to_item_tuple, to_container_id, :handle_container_update)
    end
  end

  defp container_function(container_id, fun, args) do
    Agent.get_and_update(via_tuple(container_id), fn state ->
      ret =
        apply(
          fun,
          [state.items] ++
            (args |> remove_container_id_arg() |> Keyword.values()) ++ [get_opts_for_state(state)]
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
      Container.has_room_for?(state.items, id, quantity, get_opts_for_state(state))
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

  defp get_opts_for_state(state) do
    %{
      always_stack: state.always_stack,
      capacity: state.capacity,
      hooks: state.hooks
    }
  end
end
