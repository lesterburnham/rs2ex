defmodule RS2.Packet.Decoder do
  alias RS2.Packet
  use Bitwise

  def read_int(%Packet{payload: payload} = packet) do
    <<val::32, rest::binary>> = payload
    {val, %Packet{packet | payload: rest}}
  end
end
