defmodule Rs2ex.Packet.Overflow do
  use Bitwise

  def nibble(i) do
    overflow(i &&& 0xF, 4)
  end

  def byte(i) do
    overflow(i, 7)
  end

  def ubyte(i) do
    overflow(i &&& 0xFF, 8)
  end

  def short(i) do
    overflow(i, 15)
  end

  def ushort(i) do
    overflow(i &&& 0xFFFF, 16)
  end

  def int(i) do
    overflow(i, 31)
  end

  def uint(i) do
    overflow(i &&& 0xFFFFFFFF, 32)
  end

  def long(i) do
    overflow(i, 64)
  end

  def ulong(i) do
    overflow(i &&& 0xFFFFFFFFFFFFFFFF, 64)
  end

  defp overflow(i, bits) do
    e = :math.pow(2, bits) |> round
    f = ((:math.log(e) / :math.log(2)) |> round) + 1
    g = (:math.pow(2, f) |> round) - 1

    cond do
      i < -e ->
        i &&& g

      i > e - 1 ->
        -(-i &&& g)

      true ->
        i
    end
  end
end
