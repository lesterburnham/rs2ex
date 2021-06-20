defmodule RS2.Tick.PlayerUpdate do
  use Bitwise
  alias RS2.{Player.Appearance, Player, Location, Packet}

  def build(%Player{} = player) do
    current_player_update = update_player()
    current_player_movement = current_player_movement(player)
    padded_bits = padto8(<<current_player_movement::bitstring, 0::8, 2047::11>>)

    %Packet{opcode: 81, type: :var16, payload: padded_bits <> current_player_update}
  end

  def padto8(bin) do
    remainder = rem(bit_size(bin), 8)

    if remainder == 0 do
      <<bin::bitstring>>
    else
      padding_size = 8 - remainder
      padding = <<0::size(padding_size)>>
      <<bin::bitstring, padding::bitstring>>
    end
  end

  def current_player_movement(%Player{location: location}) do
    {local_x, local_y} = Location.local_coordinates(location)

    <<1::1, 3::2, location.z::2, 1::1, 1::1, local_y::7, local_x::7>>
  end

  def update_player do
    <<0x10, appearance_block()::binary>>
  end

  def appearance_block do
    app = %Appearance{}

    props =
      <<app.gender, 0, 0, 0, 0, 0>> <>
        appearance_equipment(app) <>
        appearance_colors(app) <>
        appearance_anims() <>
        <<0::64, 30, 0::16>>

    <<-byte_size(props), props::binary>>
  end

  def appearance_equipment(%Appearance{} = appearance) do
    <<
      0x100 + appearance.chest::16,
      0,
      0x100 + appearance.arms::16,
      0x100 + appearance.legs::16,
      0x100 + appearance.head::16,
      0x100 + appearance.hands::16,
      0x100 + appearance.feet::16,
      0x100 + appearance.beard::16
    >>
  end

  def appearance_colors(%Appearance{} = appearance) do
    <<appearance.hair_color, appearance.torso_color, appearance.leg_color, appearance.feet_color,
      appearance.skin_color>>
  end

  def appearance_anims() do
    # stand, stand turn, walk, turn 180, turn 90 cw, turn 90 ccw, run
    <<0x328::16, 0x337::16, 0x333::16, 0x334::16, 0x335::16, 0x336::16, 0x338::16>>
  end
end
