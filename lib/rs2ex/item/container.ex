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

  def swap(items, from_slot, to_slot, _opts \\ %{}) do
    with {from, from_index} <-
           Enum.with_index(items) |> Enum.find(fn {item, _index} -> item.slot == from_slot end),
         {to, to_index} <-
           Enum.with_index(items) |> Enum.find(fn {item, _index} -> item.slot == to_slot end) do
      {:ok,
       items
       |> List.replace_at(from_index, %Item{from | slot: to_slot})
       |> List.replace_at(to_index, %Item{to | slot: from_slot})}
    else
      nil -> {:error, items}
    end
  end

  def set(items, slot, id, quantity, _opts \\ %{}) do
    with {item, item_index} <-
           Enum.with_index(items) |> Enum.find(fn {item, _index} -> item.slot == slot end) do
      {:ok, items |> List.replace_at(item_index, %Item{item | id: id, quantity: quantity})}
    else
      nil -> {:error, items}
    end
  end

  def insert(items, from_slot, to_slot, _opts \\ %{}) do
    # todo
    #
    # recursively swap item with its neighbor (forward or backward) until
    # item is placed into correct to_slot
  end

  def remove(items, preferred_slot, id, quantity, %{always_stack: always_stack} = opts) do
    # todo
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

  # todo listeners

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

  defp get_free_slots(items, %{capacity: capacity}) do
    all_slots = Enum.into(0..(capacity - 1), [])
    all_slots -- used_slots(items)
  end

  defp used_slots(items) do
    Enum.map(items, fn item -> item.slot end)
  end

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