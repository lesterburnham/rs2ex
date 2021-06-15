defmodule Rs2ex.Packet.Decoder do
  alias Rs2ex.Packet
  use Bitwise

  def read_int(%Packet{payload: payload} = packet) do
    <<val::32-big, rest::binary>> = payload
    {val, %Packet{packet | payload: rest}}
  end
end
