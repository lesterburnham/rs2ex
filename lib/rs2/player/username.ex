defmodule RS2.Player.Username do
  alias RS2.Packet.Overflow

  @valid_characters ~w{_ a b c d e f g h i j k l m n o p
    q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9 ! @ # $ % ^
    & * ( ) - + = : ; . > <  " [ ] | ? / `}

  def fix_name(name) do
    name
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  def format_name(name) do
    name
    |> fix_name()
    |> String.replace(" ", "_")
  end

  def valid_name?(name) do
    Regex.match?(~r/^[a-z0-9_]+$/, name)
  end

  def format_name_protocol(name) do
    name
    |> String.downcase()
    |> String.replace(" ", "_")
  end

  def name_to_long(name) do
    name
    |> String.to_charlist()
    |> Enum.reduce(0, fn c, acc ->
      cond do
        Enum.member?(?A..?Z, c) ->
          37 * acc + (1 + c) - ?A

        Enum.member?(?a..?z, c) ->
          37 * acc + (1 + c) - ?a

        Enum.member?(?0..?9, c) ->
          37 * acc + (27 + c) - ?0

        true ->
          37 * acc
      end
    end)
    |> round()
    |> strip_trailing_undercores()
  end

  def long_to_name(n) do
    n
    |> Overflow.long()
    |> convert_long_to_name()
    |> String.reverse()
  end

  defp convert_long_to_name(_n, _buffer \\ "")
  defp convert_long_to_name(0, buffer), do: buffer

  defp convert_long_to_name(n, buffer) do
    offset = (n / 37) |> round() |> Overflow.long()
    char = Enum.at(@valid_characters, n - offset * 37)
    convert_long_to_name(offset, buffer <> char)
  end

  defp strip_trailing_undercores(0), do: 0

  defp strip_trailing_undercores(val) when rem(val, 37) == 0 do
    (val / 37)
    |> round
    |> strip_trailing_undercores()
  end

  defp strip_trailing_undercores(val), do: val
end
