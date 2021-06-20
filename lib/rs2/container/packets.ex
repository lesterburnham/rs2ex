defmodule RS2.Container.Packets do
  alias RS2.Packet
  import Packet.Encoder

  def update_all_items(interface_id, items) do
    %Packet{opcode: 53, type: :var16}
    |> add_short(interface_id)
    |> add_short(items |> Enum.count())
    |> then(
      &Enum.reduce(items, &1, fn item, packet ->
        if item != nil do
          packet
          |> item_quantity(item.quantity, :add_int2)
          |> add_leshort_a(item.id + 1)
        else
          packet
          |> add_byte(0)
          |> add_leshort_a(0)
        end
      end)
    )
  end

  def update_some_items(interface_id, slots, items) do
    %Packet{opcode: 34, type: :var16}
    |> add_short(interface_id)
    |> then(
      &Enum.reduce(slots, &1, fn slot, packet ->
        item = Enum.at(items, slot)

        if item != nil do
          packet
          |> add_smart(slot)
          |> add_short(item.id + 1)
          |> item_quantity(item.quantity, :add_int)
        else
          packet
          |> add_smart(slot)
          |> add_short(0)
          |> add_byte(0)
        end
      end)
    )
  end

  def update_one_item(interface_id, slot, items) do
    update_some_items(interface_id, [slot], items)
  end

  defp item_quantity(packet, quantity, :add_int) when quantity > 254 do
    packet |> add_byte(255) |> add_int(quantity)
  end

  defp item_quantity(packet, quantity, :add_int2) when quantity > 254 do
    packet |> add_byte(255) |> add_int2(quantity)
  end

  defp item_quantity(packet, quantity, _), do: packet |> add_byte(quantity)
end
