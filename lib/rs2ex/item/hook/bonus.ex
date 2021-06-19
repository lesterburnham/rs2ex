defmodule Rs2ex.Item.Hook.Bonus do
  @behaviour Rs2ex.Item.Hook

  @bonus_names [
    "Stab",
    "Slash",
    "Crush",
    "Magic",
    "Range",
    "Stab",
    "Slash",
    "Crush",
    "Magic",
    "Range",
    "Strength",
    "Prayer"
  ]

  @bonus_keys [
    :att_stab_bonus,
    :att_slash_bonus,
    :att_crush_bonus,
    :att_magic_bonus,
    :att_ranged_bonus,
    :def_stab_bonus,
    :def_slash_bonus,
    :def_crush_bonus,
    :def_magic_bonus,
    :def_ranged_bonus,
    :strength_bonus,
    :prayer_bonus
  ]

  def handle_slot_set(items, _slot) do
    update_bonuses(items)
  end

  def handle_slot_swap(items, _from_slot, _to_slot) do
    update_bonuses(items)
  end

  def handle_container_update(items) do
    update_bonuses(items)
  end

  def update_bonuses(items) do
    # todo: use packet 126 (send_string)
    items
    |> build_bonus_text()
    |> Enum.with_index()
    |> Enum.each(fn {text, index} ->
      id = if index >= 10, do: 1675 + index + 1, else: 1675 + index

      IO.puts("send string: #{id}, #{text}")

      case Registry.lookup(Rs2ex.Xyz, "mopar") do
        [{pid, _}] ->
          GenServer.call(pid, {:send_packet, Rs2ex.CommandEncoder.send_string(id, text)})

        _ ->
          nil
      end
    end)
  end

  def calculate_bonus(items, bonus_key) do
    {_, bonus} =
      items
      |> Enum.map_reduce(0, fn item, sum ->
        {item, sum + item_bonus(item, bonus_key)}
      end)

    bonus
  end

  defp item_bonus(nil, _bonus_key), do: 0

  defp item_bonus(item, bonus_key) do
    Rs2ex.Item.Definition.for_id(item.id) |> Map.get(bonus_key)
  end

  def build_bonus_text(items) do
    @bonus_keys
    |> Enum.with_index()
    |> Enum.map(fn {bonus_key, index} ->
      Enum.at(@bonus_names, index) |> bonus_text(calculate_bonus(items, bonus_key))
    end)
  end

  defp bonus_text(name, bonus) do
    sign = if bonus >= 0, do: "+", else: ""
    "#{name}: #{sign}#{bonus}"
  end
end
