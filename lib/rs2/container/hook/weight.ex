defmodule RS2.Container.Hook.Weight do
  @behaviour RS2.Container.Hook

  def handle_slot_set(session, items, _slot) do
    update_weight(session, items)
  end

  def handle_slot_swap(session, items, _from_slot, _to_slot) do
    update_weight(session, items)
  end

  def handle_container_update(session, items) do
    update_weight(session, items)

    IO.puts("hello")

    weight = calculate_weight(items)

    IO.puts("weight: #{weight}")
  end

  def update_weight(session, items) do
    # so I guess we just ignore the items passed in?
    # shit this uses inventory AND equipment weights

    RS2.Session.send_packet(
      session,
      items |> calculate_weight() |> RS2.CommandEncoder.update_weight()
    )
  end

  def calculate_weight(items) do
    {_, weight} =
      items
      |> Enum.map_reduce(0.0, fn item, sum ->
        if item do
          {item, sum + RS2.Container.Item.Definition.for_id(item.id).weight}
        else
          {item, sum}
        end
      end)

    weight |> round
  end
end
