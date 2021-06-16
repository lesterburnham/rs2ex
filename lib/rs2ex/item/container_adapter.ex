defmodule Rs2ex.Item.ContainerAdapter do
  alias Rs2ex.Item

  # todo: need player reference

  # old: slot_change
  @callback handle_slot_set(items :: list(%Item{}), slot :: integer) :: :ok

  # old: slots_changed
  @callback handle_slot_swap(items :: list(%Item{}), slots :: list(integer)) :: :ok

  # old: items_changed
  @callback handle_container_update(items :: list(%Item{})) :: :ok
end
