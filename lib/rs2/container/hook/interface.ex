defmodule RS2.Container.Hook.Interface do
  @behaviour RS2.Container.Hook

  require Logger

  def handle_slot_set(session, items, slot, %{interface_id: interface_id}) do
    Logger.info("test 1 #{slot}")

    RS2.Session.send_packet(
      session,
      RS2.Container.Packets.update_one_item(interface_id, slot, items)
    )
  end

  def handle_slot_swap(session, items, from_slot, to_slot, %{interface_id: interface_id}) do
    Logger.info("test 2 #{from_slot}, #{to_slot}")

    RS2.Session.send_packet(
      session,
      RS2.Container.Packets.update_some_items(interface_id, [from_slot, to_slot], items)
    )
  end

  def handle_container_update(session, items, %{interface_id: interface_id}) do
    Logger.info("test 3")

    RS2.Session.send_packet(session, RS2.Container.Packets.update_all_items(interface_id, items))
  end
end
