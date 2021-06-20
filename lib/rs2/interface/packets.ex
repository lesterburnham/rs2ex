defmodule RS2.Interface.Packets do
  alias RS2.Packet
  import Packet.Encoder

  def open_interface(interface_id, walkable \\ false) do
    opcode = if walkable, do: 208, else: 97

    packet = %Packet{opcode: opcode}

    if walkable do
      packet
      |> add_leshort(interface_id)
    else
      packet
      |> add_short(interface_id)
    end
  end

  def send_interface_inventory(interface_id, inventory_id) do
    %Packet{opcode: 248}
    |> add_short_a(interface_id)
    |> add_short(inventory_id)
  end

  def clear_screen() do
    %Packet{opcode: 219}
  end
end
