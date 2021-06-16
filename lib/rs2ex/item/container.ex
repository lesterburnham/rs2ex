defmodule Rs2ex.Item.Container do
  alias Rs2ex.Item
  alias Rs2ex.Item.Definition

  @max_quantity 2_147_483_647

  def add_item(items, id, quantity, %{always_stack: always_stack, capacity: _capacity} = opts) do
    if always_stack || stackable_item?(id) do
      items
      |> Enum.with_index()
      |> Enum.find(fn {item, _index} -> item.id == id end)
      |> add_stackable_item(items, id, quantity, opts)
    else
      if free_slot_count(items, opts) >= quantity do
        {:ok, items ++ fill_free_slots(items, id, quantity, opts)}
      else
        {:full, items}
      end
    end
  end

  def swap(items, from_slot, to_slot) do
    from = Enum.at(items, from_slot)
    to = Enum.at(items, to_slot)

    if Enum.any?([from, to], &is_nil/1) do
      {:error, items}
    else
      {:ok,
       items
       |> List.replace_at(from_slot, %Item{from | slot: to_slot})
       |> List.replace_at(to_slot, %Item{to | slot: from_slot})}
    end
  end

  def total_quantity_of_id(items, id) do
    {_, quantity} =
      items
      |> Enum.map_reduce(0, fn item, sum ->
        if item.id == id do
          {item, sum + item.quantity}
        else
          {item, sum}
        end
      end)

    quantity
  end

  # remove
  # insert
  # set
  # listeners

  defp add_stackable_item({item, index}, items, _id, quantity, _) do
    if item.quantity + quantity > @max_quantity do
      {:full, items}
    else
      {:ok, List.replace_at(items, index, %Item{item | quantity: item.quantity + quantity})}
    end
  end

  defp add_stackable_item(nil, items, id, quantity, opts) do
    case get_free_slots(items, opts) do
      [] ->
        {:full, items}

      slots ->
        if quantity > @max_quantity do
          {:full, items}
        else
          {:ok, items ++ [%Item{id: id, quantity: quantity, slot: slots |> hd}]}
        end
    end
  end

  defp fill_free_slots(items, id, quantity, opts) do
    get_free_slots(items, opts)
    |> Enum.take(quantity)
    |> Enum.map(fn slot ->
      %Item{id: id, quantity: 1, slot: slot}
    end)
  end

  # list_a = sort all of the items
  # lost_b = get a list of logs
  # take(quantity) from list_b
  # subtract list_b from list_a

  defp get_free_slots(items, %{capacity: capacity}) do
    all_slots = Enum.into(0..(capacity - 1), [])
    all_slots -- used_slots(items)
  end

  defp used_slots(items) do
    Enum.map(items, fn item -> item.slot end)
  end

  # set_item, delete existing and then add new one

  defp used_slot_count(items) do
    items |> Enum.count()
  end

  defp free_slot_count(items, %{capacity: capacity}) do
    capacity - used_slot_count(items)
  end

  def stackable_item?(id) do
    Definition.for_id(id).stackable
  end
end
