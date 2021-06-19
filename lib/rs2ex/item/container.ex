defmodule Rs2ex.Item.Container do
  alias Rs2ex.Item
  alias Rs2ex.Item.Definition
  @max_quantity 2_147_483_647

  def add_item(items, id, quantity, %{always_stack: always_stack, capacity: _capacity} = opts)
      when quantity > 0 do
    if always_stack || stackable_item?(id) do
      items
      |> Enum.with_index()
      |> Enum.find(fn {item, _index} -> !!item and item.id == id end)
      |> add_stackable_item(items, id, quantity, opts)
    else
      if free_slot_count(items, opts) >= quantity do
        {:ok, fill_free_slots(items, id, quantity, opts)}
      else
        {:full, items}
      end
    end
  end

  def add_item(items, _id, _quantity, _opts), do: {:error, items}

  def swap(items, from_slot, to_slot, %{capacity: capacity}) do
    if Enum.all?([from_slot, to_slot], &slot_in_range(&1, capacity)) do
      from = get_item_at_slot(items, from_slot)
      to = get_item_at_slot(items, to_slot)

      {:ok,
       items
       |> replace_item_at_slot(from_slot, to)
       |> replace_item_at_slot(to_slot, from)}
    else
      {:error, items}
    end
  end

  defp slot_in_range(slot, capacity) when slot in 0..(capacity - 1), do: true
  defp slot_in_range(_, _), do: false

  defp replace_item_at_slot(items, nil, _), do: items

  defp replace_item_at_slot(items, index, item) do
    List.replace_at(items, index, item)
  end

  defp get_item_at_slot(items, slot) do
    case Enum.fetch(items, slot) do
      {:ok, item} ->
        item

      _ ->
        {:error, items}
    end
  end

  def set(items, slot, id, quantity, _opts \\ %{}) do
    case get_item_at_slot(items, slot) do
      {:error, items} ->
        {:error, items}

      item ->
        {:ok, items |> List.replace_at(slot, %Item{item | id: id, quantity: quantity})}
    end
  end

  def has_room_for?(_items) do
  end

  def insert(items, from_slot, to_slot, _opts \\ %{}) do
    with {item, items} <- List.pop_at(items, from_slot),
         items <- List.insert_at(items, to_slot, item) do
      items
    end
  end

  def remove(_items, _preferred_slot, _id, _quantity, %{always_stack: _always_stack} = _opts) do
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
    case get_free_slots_indexes(items, opts) do
      [] ->
        {:full, items}

      slots ->
        if quantity > @max_quantity do
          {:full, items}
        else
          {:ok, List.replace_at(items, slots |> hd, %Item{id: id, quantity: quantity})}
        end
    end
  end

  defp fill_free_slots(items, id, quantity, opts) do
    free_slot_indexes =
      get_free_slots_indexes(items, opts)
      |> Enum.take(quantity)

    items
    |> Enum.with_index()
    |> Enum.map(fn {item, index} ->
      if Enum.member?(free_slot_indexes, index) do
        %Item{id: id, quantity: 1}
      else
        item
      end
    end)
  end

  defp get_free_slots_indexes(items, %{capacity: capacity}) do
    all_slots = Enum.into(0..(capacity - 1), [])
    all_slots -- used_slots_indexes(items)
  end

  defp used_slots_indexes(items) do
    Enum.with_index(items)
    |> Enum.reject(fn {item, _index} -> item == nil end)
    |> Enum.map(fn {_item, index} -> index end)
  end

  defp used_slot_count(items) do
    items |> Enum.reject(fn item -> item == nil end) |> Enum.count()
  end

  defp free_slot_count(items, %{capacity: capacity}) do
    capacity - used_slot_count(items)
  end

  def stackable_item?(id) do
    Definition.for_id(id).stackable
  end
end
