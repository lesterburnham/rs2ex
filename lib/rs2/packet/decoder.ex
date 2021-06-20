defmodule RS2.Packet.Decoder do
  alias RS2.Packet
  alias RS2.Packet.Overflow

  use Bitwise

  def read_byte(%Packet{payload: payload} = packet) do
    <<val, rest::binary>> = payload
    {val, %Packet{packet | payload: rest}}
  end

  def read_ubyte(%Packet{payload: payload} = packet) do
    <<val, rest::binary>> = payload
    {Overflow.ubyte(val), %Packet{packet | payload: rest}}
  end

  def read_int(%Packet{payload: payload} = packet) do
    <<val::32, rest::binary>> = payload
    {val, %Packet{packet | payload: rest}}
  end

  def read_short(%Packet{payload: payload} = packet) do
    <<val::16, rest::binary>> = payload
    {val, %Packet{packet | payload: rest}}
  end

  def read_short_a(%Packet{payload: payload} = packet) do
    <<a, b, rest::binary>> = payload

    val = a <<< 8 ||| Overflow.ubyte(b - 128)

    if val > 32_767 do
      {Overflow.short(val - 0x10000), %Packet{packet | payload: rest}}
    else
      {Overflow.short(val), %Packet{packet | payload: rest}}
    end
  end

  def read_str(%Packet{payload: payload} = packet) do
    [val, rest] = String.split(payload, <<10>>)
    {val, %Packet{packet | payload: rest}}
  end
end
