defmodule RS2.Interface.Packets do
  alias RS2.Packet
  import Packet.Encoder

  def open_interface(interface_id, walkable \\ false) do
    if walkable do
      %Packet{opcode: 208}
      |> add_leshort(interface_id)
    else
      %Packet{opcode: 97}
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
