defmodule RS2.CommandEncoder do
  alias RS2.{Player, Packet, Location}
  import Packet.Encoder

  @sidebar_interfaces [
    [1, 3917],
    [2, 638],
    [3, 3213],
    [4, 1644],
    [5, 5608],
    [6, 1151],
    [8, 5065],
    [9, 5715],
    [10, 2449],
    [11, 4445],
    [12, 147],
    [13, 6299],
    [0, 2423]
  ]

  def initialize_player(%Player{member: member, index: index}) do
    %Packet{opcode: 249}
    |> add_byte_a(if member, do: 1, else: 0)
    |> add_leshort_a(index)
  end

  def send_message(message) do
    %Packet{opcode: 253, type: :var8}
    |> add_str(message)
  end

  def logout(), do: %Packet{opcode: 109}

  def reset_camera(), do: %Packet{opcode: 107}

  def load_map_region(%Location{} = location) do
    {region_x, region_y} = Location.region_coordinates(location)

    %Packet{opcode: 73}
    |> add_short_a(region_x + 6)
    |> add_short(region_y + 6)
  end

  def display_player_option(option, slot, top) do
    %Packet{opcode: 104, type: :var8}
    |> add_byte_c(slot)
    |> add_byte_a(if top, do: 0, else: 1)
    |> add_str(option)
  end

  def update_weight(weight) do
    %Packet{opcode: 240}
    |> add_short(weight)
  end

  def friend_server_status(status) do
    %Packet{opcode: 221}
    |> add_byte(status)
  end

  def send_string(id, str) do
    %Packet{opcode: 126, type: :var16}
    |> add_str(str)
    |> add_short_a(id)
  end

  def send_sidebar_interface(icon, id) do
    %Packet{opcode: 71}
    |> add_short(id)
    |> add_byte_a(icon)
  end

  def send_sidebar_interfaces() do
    @sidebar_interfaces
    |> Enum.map(fn [icon | [interface]] ->
      send_sidebar_interface(icon, interface)
    end)
  end
end
