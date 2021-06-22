defmodule RS2.Player.Equipment do
  # HEAD: 0
  # CAPE: 1
  # AMULET: 2
  # WEAPON: 3
  # CHEST: 4
  # SHIELD: 5
  # LEGS: 7
  # HANDS: 9
  # FEET: 10
  # RING: 12
  # ARROWS: 13

  defp via_tuple(container_id), do: {:via, Registry, {RS2.Container.Registry, container_id}}

  def equip_item(inventory_container_id, equipment_container_id, from_slot, id) do
    Agent.get_and_update(via_tuple(equipment_container_id), fn equipment_state ->
      Agent.get_and_update(via_tuple(inventory_container_id), fn inventory_state ->

        item_at_slot =
          inventory_state.items
          |> RS2.Container.get_item_at_slot(from_slot)

        case item_at_slot do
          {:ok, item} ->
            if item != nil and item.id == id do
              # todo

              {:ok}
            else
              {:error}
            end

          _ ->
            {:error}
        end
      end)
    end)
  end

  defp get_equipment_slot_exception(_id) do
    # todo
    # check if this id has an exception slot set

    nil
  end

  defp get_equipment_slot_for_id(id, _name) do
    case get_equipment_slot_exception(id) do
      nil ->
        # todo
        # use name regex to get slot out of data
        3

      slot ->
        slot
    end
  end
end
