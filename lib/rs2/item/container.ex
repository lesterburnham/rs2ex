defmodule RS2.Item.Container do
  alias RS2.Item
  alias RS2.Item.Definition
  @max_quantity 2_147_483_647

  def add_item(items, id, quantity, %{always_stack: always_stack} = opts) when quantity > 0 do
    if always_stack || stackable_item?(id) do
      items
      |> Enum.with_index()
      |> Enum.find(fn {item, _index} -> item != nil and item.id == id end)
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

  def swap_item(items, from_slot, to_slot, %{capacity: capacity}) do
    if Enum.all?([from_slot, to_slot], &slot_in_range(&1, capacity)) do
      case get_item_at_slot(items, from_slot) do
        nil ->
          {:error, items}

        from ->
          to = get_item_at_slot(items, to_slot)

          {:ok,
           items
           |> replace_item_at_slot(from_slot, to)
           |> replace_item_at_slot(to_slot, from)}
      end
    else
      {:error, items}
    end
  end

  defp slot_in_range(slot, capacity) when slot in 0..(capacity - 1), do: true
  defp slot_in_range(_, _), do: false

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

  defp get_item_for_id(items, id) do
    items
    |> Enum.find(fn item -> item != nil and item.id == id end)
  end

  @spec get_slot_for_item(list(%Item{}), integer()) :: integer() | nil
  defp get_slot_for_item(items, id) do
    items
    |> Enum.find_index(fn item -> item != nil and item.id == id end)
  end

  def set_item(items, slot, nil, %{capacity: capacity}) do
    if slot_in_range(slot, capacity) do
      {:ok, List.replace_at(items, slot, nil)}
    else
      {:error, items}
    end
  end

  def set_item(items, slot, id, quantity, _opts \\ %{}) do
    case get_item_at_slot(items, slot) do
      {:error, items} ->
        {:error, items}

      item ->
        {:ok, items |> List.replace_at(slot, %Item{item | id: id, quantity: quantity})}
    end
  end

  def has_room_for?(items, id, quantity, %{always_stack: always_stack} = opts)
      when quantity > 0 do
    if always_stack || stackable_item?(id) do
      case get_item_for_id(items, id) do
        nil ->
          free_slot_count(items, opts) >= 1

        item ->
          item.quantity + quantity <= @max_quantity
      end
    else
      free_slot_count(items, opts) >= quantity
    end
  end

  def has_room_for?(_items, _id, _quantity, _opts), do: false

  def insert(items, from_slot, to_slot, _opts \\ %{}) do
    with {item, items} <- List.pop_at(items, from_slot),
         items <- List.insert_at(items, to_slot, item) do
      {:ok, items}
    end
  end

  def remove_item(items, id, quantity, opts) do
    remove_item(items, id, quantity, -1, opts)
  end

  def remove_item(items, id, quantity, preferred_slot, %{always_stack: always_stack} = opts) do
    if always_stack || stackable_item?(id) do
      items
      |> remove_stackable_item(id, quantity, opts)
    else
      items
      |> remove_single_item(id, quantity, preferred_slot, opts)
    end
  end

  defp remove_stackable_item(items, id, quantity, opts) do
    case get_slot_for_item(items, id) do
      nil ->
        {:error, items}

      slot ->
        item = get_item_at_slot(items, slot)

        if item.quantity > quantity do
          items
          |> set_item(slot, id, item.quantity - quantity)
          |> Tuple.append([slot])
          |> Tuple.append(quantity)
        else
          items
          |> set_item(slot, nil, opts)
          |> Tuple.append([slot])
          |> Tuple.append(item.quantity)
        end
    end
  end

  defp remove_single_item(items, id, quantity, preferred_slot, _opts) do
    item_indexes = get_slots_for_item(items, id)

    if Enum.empty?(item_indexes) do
      {:error, items}
    else
      remove_indexes =
        if preferred_slot != -1 do
          Enum.find(item_indexes, item_indexes |> hd, fn slot ->
            case get_item_at_slot(items, preferred_slot) do
              {:error, _} ->
                false

              item ->
                item.id == id && slot == preferred_slot
            end
          end)
          |> List.wrap()
        else
          item_indexes |> Enum.take(quantity)
        end

      new_items =
        items
        |> Enum.with_index()
        |> Enum.map(fn {item, index} ->
          if Enum.member?(remove_indexes, index) do
            nil
          else
            item
          end
        end)

      {:ok, new_items, remove_indexes, Enum.count(remove_indexes)}
    end
  end

  def clear_items(_items, %{capacity: capacity} = _opts) do
    {:ok, List.duplicate(nil, capacity)}
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

  defp get_slots_for_item(items, id) do
    Enum.with_index(items)
    |> Enum.filter(fn {item, _index} -> item != nil and item.id == id end)
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
