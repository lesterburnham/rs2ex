defmodule RS2.Packet.Encoder do
  alias RS2.Packet
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

  def add_smart(%Packet{} = packet, val) when val >= 128, do: add_short(packet, val + 32_768)

  def add_smart(%Packet{} = packet, val), do: add_byte(packet, val)

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

  def add_int(%Packet{payload: payload} = packet, val) do
    %Packet{packet | payload: payload <> <<val >>> 24, val >>> 16, val >>> 8, val>>}
  end

  def add_int2(%Packet{payload: payload} = packet, val) do
    %Packet{packet | payload: payload <> <<val >>> 16, val >>> 24, val, val >>> 8>>}
  end
end
