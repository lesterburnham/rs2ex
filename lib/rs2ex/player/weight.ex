defmodule Rs2ex.Player.Weight do
  @behaviour Rs2ex.Item.ContainerAdapter

  def handle_slot_set(_items, _slot) do
    update_weight()
  end

  def handle_slot_swap(_items, _slots) do
    update_weight()
  end

  def handle_container_update(_items) do
    IO.puts("hello")
    update_weight()
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
        {item, sum + Rs2ex.Item.Definition.for_id(item.id).weight}
      end)

    weight |> round
  end
end

# l = [&Rs2ex.Player.Weight.handle_container_update/1]
# Enum.each(l, fn f -> f.([]) end)

# interface container listener usually has state (interface id)