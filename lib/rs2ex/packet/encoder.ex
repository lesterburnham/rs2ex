defmodule Rs2ex.Packet.Encoder do
  alias Rs2ex.Packet
  use Bitwise

  def add_byte(%Packet{payload: payload} = packet, val) do
    %Packet{packet | payload: payload <> <<val>>}
  end

  def add_byte_a(%Packet{} = packet, val), do: packet |> add_byte(val + 128)

  def add_byte_c(%Packet{} = packet, val), do: packet |> add_byte(-val)

  def add_byte_s(%Packet{} = packet, val), do: packet |> add_byte(128 - val)

  def add_str(%Packet{payload: payload} = packet, val) do
    %Packet{packet | payload: payload <> val <> <<10>>}
  end

  def add_short(%Packet{payload: payload} = packet, val) do
    %Packet{packet | payload: payload <> <<val >>> 8, val>>}
  end

  def add_short_a(%Packet{payload: payload} = packet, val) do
    %Packet{packet | payload: payload <> <<val >>> 8, val + 128>>}
  end

  def add_leshort(%Packet{payload: payload} = packet, val) do
    %Packet{packet | payload: payload <> <<val, val >>> 8>>}
  end

  def add_leshort_a(%Packet{payload: payload} = packet, val) do
    %Packet{packet | payload: payload <> <<val + 128, val >>> 8>>}
  end
end
