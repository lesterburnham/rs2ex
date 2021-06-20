defmodule RS2.Container.Hook.Interface do
  @behaviour RS2.Container.Hook

  require Logger

  def handle_slot_set(_session, _items, slot, %{interface_id: _interface_id}) do
    # send_update_item(@interface_id, slot, container.items[slot])
    Logger.info("test 1 #{slot}")
  end

  def handle_slot_swap(_session, _items, _from_slot, _to_slot, %{interface_id: _interface_id}) do
    # send_update_some_items(@interface_id, slots, container.items)
    Logger.info("test 2")
  end

  def handle_container_update(session, items, %{interface_id: interface_id}) do
    Task.async(fn ->
      RS2.Session.send_packet(session, RS2.CommandEncoder.send_update_items(interface_id, items))
    end)
  end
end
