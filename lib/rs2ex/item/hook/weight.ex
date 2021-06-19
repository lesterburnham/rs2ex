defmodule Rs2ex.Item.Hook.Weight do
  @behaviour Rs2ex.Item.Hook

  def handle_slot_set(_items, _slot) do
    update_weight()
  end

  def handle_slot_swap(_items, _from_slot, _to_slot) do
    update_weight()
  end

  def handle_container_update(items) do
    IO.puts("hello")
    # update_weight()

    weight = calculate_weight(items)

    IO.puts("weight: #{weight}")
  end

  def update_weight do
    # so I guess we just ignore the items passed in?
    # shit this uses inventory AND equipment weights

    # GenServer.call(pid, {:send_packet, Rs2ex.CommandEncoder.update_weight(weight)})
  end

  def calculate_weight(items) do
    {_, weight} =
      items
      |> Enum.map_reduce(0.0, fn item, sum ->
        if item do
          {item, sum + Rs2ex.Item.Definition.for_id(item.id).weight}
        else
          {item, sum}
        end
      end)

    weight |> round
  end
end
