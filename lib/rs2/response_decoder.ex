defmodule RS2.ResponseDecoder do
  require Logger

  alias RS2.Packet
  alias RS2.Packet.Overflow

  import Packet.Decoder

  use Bitwise

  @ignore_opcodes Code.eval_string("""
                  [
                  0, 77, 78, 3, 226, 148, 36,
                  246, 165, 121, 150, 238, 183,
                  230, 136, 189, 152, 200, 85
                  ]
                  """)
                  |> elem(0)

  # enter new region
  def decode(%Packet{opcode: 210}) do
    Logger.info("enter new region")
  end

  # chat message
  def decode(%Packet{opcode: 4}) do
    Logger.error("chat message")
  end

  # idle logout
  def decode(%Packet{opcode: 202}) do
    # Logger.info("idle logout")
    # RS2.Session.send_packet("mopar", RS2.CommandEncoder.logout())
  end

  # item option 1
  def decode(%Packet{opcode: 145} = packet) do
    with {interface_id, packet} <- cast(packet |> read_short_a(), &Overflow.ushort/1),
         {slot, packet} <- cast(packet |> read_short_a(), &Overflow.ushort/1),
         {id, _} <- cast(packet |> read_short_a(), &Overflow.ushort/1) do
      case interface_id do
        1688 ->
          RS2.Container.Server.transfer_item(
            {"mopar", :equipment},
            {"mopar", :inventory},
            slot,
            id
          )

        _ ->
          Logger.debug(
            "unhandled item option 1, interface_id: #{interface_id}, slot: #{slot}, id: #{id}"
          )
      end
    end
  end

  # add friend
  def decode(%Packet{opcode: 188} = packet) do
    with {name_long, _packet} <- packet |> read_long() do
      name = RS2.Player.Username.long_to_name(name_long)
      Logger.debug("add friend: #{name} (#{name_long})")
    end
  end

  # item swap
  def decode(%Packet{opcode: 214} = packet) do
    with {interface_id, packet} <- packet |> read_leshort_a(),
         {_, packet} <- packet |> read_byte_c(),
         {from_slot, packet} <- packet |> read_leshort_a(),
         {to_slot, _packet} <- packet |> read_leshort() do
      case container_for_interface(interface_id) do
        nil ->
          Logger.debug("unhandled swap for interface: #{interface_id}")

        container ->
          RS2.Container.Server.swap_item({"mopar", container}, from_slot, to_slot)
      end
    end
  end

  # command
  def decode(%Packet{opcode: 103} = packet) do
    with {command, _} <- packet |> read_str(),
         [command | args] <- command |> String.split(" ") do
      RS2.Interface.Command.handle_command("mopar", command, args)
    end
  end

  # button click
  def decode(%Packet{opcode: 185} = packet) do
    {button_id, _packet} = packet |> read_short()

    Logger.debug("button click id: #{button_id}")

    RS2.Interface.Button.handle_click("mopar", button_id)
  end

  # camera move
  def decode(%Packet{opcode: 86} = packet) do
    with {height, packet} <- packet |> read_short(),
         _height <- (Overflow.ushort(height) - 128) |> Overflow.ubyte(),
         {rotation, _packet} <- packet |> read_short_a(),
         _rotation <- (Overflow.ushort(rotation) * 45) >>> 8 do
      # Logger.debug("camera move height: #{height}, rotation: #{rotation}")
    end
  end

  # on_packet(86) {|player, packet|
  #   height = (packet.read_short.ushort - 128).ubyte
  #   rotation = (packet.read_short_a.ushort * 45) >> 8

  # mouse click
  def decode(%Packet{opcode: 241} = packet) do
    {raw, _packet} = packet |> read_int()

    time = (raw >>> 20 &&& 4095) * 50
    button = raw >>> 19 &&& 1
    coords = raw &&& 0x7FFFF
    y = trunc(coords / 765)
    x = trunc(coords - y * 765)

    Logger.debug("mouse click x: #{x}, y: #{y}, button: #{button}, time: #{time}")
  end

  # ignore
  def decode(%Packet{opcode: opcode}) when opcode in @ignore_opcodes do
  end

  def decode(%Packet{opcode: opcode, payload: payload}) do
    Logger.warn(
      "unhandled packet (opcode: #{opcode}, payload: #{inspect(payload, [{:binaries, :as_binaries}, {:limit, :infinity}])})"
    )
  end

  # normal inventory
  defp container_for_interface(3214), do: :inventory
  # inventory while in bank?
  defp container_for_interface(5064), do: :inventory
  defp container_for_interface(5382), do: :bank

  defp container_for_interface(_), do: nil

  defp cast(tuple, fun) do
    {val, packet} = tuple
    {fun.(val), packet}
  end
end
