defmodule Rs2ex.Item.Container do
  alias Rs2ex.Item
  alias Rs2ex.Item.Definition

  @max_quantity 2_147_483_647

  def add_item(items, id, quantity, %{always_stack: always_stack, capacity: _capacity} = opts)
      when quantity > 0 do
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

  def add_item(items, _id, _quantity, _opts), do: {:error, items}

  def swap(items, from_slot, to_slot, %{capacity: capacity}) do
    if Enum.all?([from_slot, to_slot], &slot_in_range(&1, capacity)) do
      {from, from_index} = get_item_at_slot(items, from_slot)
      {to, to_index} = get_item_at_slot(items, to_slot)

      {:ok,
       items
       |> replace_item_at_slot(from_index, from, to_slot)
       |> replace_item_at_slot(to_index, to, from_slot)}
    else
      {:error, items}
    end
  end

  defp slot_in_range(slot, capacity) when slot in 0..(capacity - 1), do: true
  defp slot_in_range(_, _), do: false

  defp replace_item_at_slot(items, nil, _, _), do: items

  defp replace_item_at_slot(items, index, item, slot) do
    List.replace_at(items, index, %Item{item | slot: slot})
  end

  defp get_item_at_slot(items, slot) do
    case Enum.with_index(items) |> Enum.find(fn {item, _index} -> item.slot == slot end) do
      {item, index} ->
        {item, index}

      _ ->
        {nil, nil}
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

  def has_room_for?(_items) do
  end

  def insert(_items, _from_slot, _to_slot, _opts \\ %{}) do
    # todo
    #
    # recursively swap item with its neighbor (forward or backward) until
    # item is placed into correct to_slot


    
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
