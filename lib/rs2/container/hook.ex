defmodule RS2.Container.Hook do
  alias RS2.Container.Item

  # todo: need player reference

  # old: slot_change
  @callback handle_slot_set(session :: String.t(), items :: list(%Item{}), slot :: integer) :: :ok

  # old: slots_changed
  @callback handle_slot_swap(
              session :: String.t(),
              items :: list(%Item{}),
              from_slot :: integer,
              to_slot :: integer
            ) ::
              :ok

  # old: items_changed
  @callback handle_container_update(session :: String.t(), items :: list(%Item{})) :: :ok
end
