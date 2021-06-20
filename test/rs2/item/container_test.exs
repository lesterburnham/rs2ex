defmodule RS2.Item.ContainerTest do
  use ExUnit.Case
  alias RS2.Item
  alias RS2.Item.Container

  test "check if item is stackable" do
    assert Container.stackable_item?(995) == true
    assert Container.stackable_item?(4151) == false
  end

  test "adding items with always_stack should override normal item stacking" do
    items = List.duplicate(nil, 10)

    assert Container.add_item(items, 4151, 100, %{capacity: 10, always_stack: true}) ==
             {:ok, [%Item{id: 4151, quantity: 100}, nil, nil, nil, nil, nil, nil, nil, nil, nil]}
  end

  test "adding stackable item with existing stack" do
    opts = %{capacity: 4, always_stack: false}

    items = [
      %Item{id: 995, quantity: 1},
      nil,
      nil,
      nil
    ]

    # normal case
    assert Container.add_item(items, 995, 500, opts) ==
             {:ok, [%RS2.Item{id: 995, quantity: 501}, nil, nil, nil]}

    # exceeding max quantity
    assert Container.add_item(items, 995, 2_147_483_647, opts) == {:full, items}

    assert Container.add_item(items, 995, 2_147_483_647 - 1, opts) ==
             {:ok, [%RS2.Item{id: 995, quantity: 2_147_483_647}, nil, nil, nil]}
  end

  test "adding stackable item with non existing stack" do
    opts = %{capacity: 4, always_stack: false}

    # normal case
    assert Container.add_item([nil], 995, 100, opts) ==
             {:ok, [%Item{id: 995, quantity: 100}]}

    # no free slots
    items = [
      %Item{id: 4151, quantity: 1},
      %Item{id: 4151, quantity: 1},
      %Item{id: 4151, quantity: 1},
      %Item{id: 4151, quantity: 1}
    ]

    assert Container.add_item(items, 995, 100, opts) == {:full, items}

    # exceeding max quantity
    assert Container.add_item([nil, nil, nil, nil], 995, 2_147_483_647 + 1, opts) ==
             {:full, [nil, nil, nil, nil]}

    assert Container.add_item([nil, nil, nil, nil], 995, 2_147_483_647, opts) ==
             {:ok, [%RS2.Item{id: 995, quantity: 2_147_483_647}, nil, nil, nil]}
  end

  test "adding non stackable item" do
    opts = %{capacity: 4, always_stack: false}

    # adding 2 when at 2 = ok
    # adding 3 when at 2 = full

    # adding max capacity to empty container
    assert Container.add_item([nil, nil, nil, nil], 4151, 4, opts) ==
             {:ok,
              [
                %RS2.Item{id: 4151, quantity: 1},
                %RS2.Item{id: 4151, quantity: 1},
                %RS2.Item{id: 4151, quantity: 1},
                %RS2.Item{id: 4151, quantity: 1}
              ]}

    # adding to a full container
    full_container = [
      %RS2.Item{id: 4151, quantity: 1},
      %RS2.Item{id: 4151, quantity: 1},
      %RS2.Item{id: 4151, quantity: 1},
      %RS2.Item{id: 4151, quantity: 1}
    ]

    assert Container.add_item(full_container, 4151, 1, opts) == {:full, full_container}

    # adding enough to fill remaining slots
    partial_container = [
      %RS2.Item{id: 4151, quantity: 1},
      %RS2.Item{id: 4151, quantity: 1},
      nil,
      nil
    ]

    assert Container.add_item(partial_container, 4151, 2, opts) == {:ok, full_container}

    # adding too many for the remaining slots
    assert Container.add_item(partial_container, 4151, 3, opts) == {:full, partial_container}

    # quantity must be greater than 0
    assert Container.add_item([], 4151, 0, %{capacity: 4, always_stack: true}) == {:error, []}

    assert Container.add_item([%RS2.Item{id: 995, quantity: 100}], 995, 0, opts) ==
             {:error, [%RS2.Item{id: 995, quantity: 100}]}
  end

  test "swapping item slots" do
    items = [
      %RS2.Item{id: 1265, quantity: 1},
      %RS2.Item{id: 1267, quantity: 1},
      %RS2.Item{id: 1269, quantity: 1},
      nil
    ]

    opts = %{capacity: 4, always_stack: false}

    # normal case
    assert Container.swap_item(items, 1, 2, opts) ==
             {:ok,
              [
                %RS2.Item{id: 1265, quantity: 1},
                %RS2.Item{id: 1269, quantity: 1},
                %RS2.Item{id: 1267, quantity: 1},
                nil
              ]}

    # swap to empty slot
    assert Container.swap_item(items, 1, 3, opts) ==
             {:ok,
              [
                %RS2.Item{id: 1265, quantity: 1},
                nil,
                %RS2.Item{id: 1269, quantity: 1},
                %RS2.Item{id: 1267, quantity: 1}
              ]}

    # swap empty slot to empty slot
    assert Container.swap_item([nil, nil, nil, nil], 1, 2, opts) == {:error, [nil, nil, nil, nil]}

    # swap empty slot to filled slot
    assert Container.swap_item(items, 3, 0, opts) == {:error, items}

    # invalid slot
    assert Container.swap_item(items, 1, 10, opts) == {:error, items}
    assert Container.swap_item(items, 10, 1, opts) == {:error, items}
  end

  test "setting item slots" do
    opts = %{capacity: 4, always_stack: false}

    items = [
      %RS2.Item{id: 1265, quantity: 1},
      %RS2.Item{id: 1267, quantity: 1},
      %RS2.Item{id: 1269, quantity: 1}
    ]

    # normal case
    assert Container.set_item(items, 1, 4151, 1) ==
             {:ok,
              [
                %RS2.Item{id: 1265, quantity: 1},
                %RS2.Item{id: 4151, quantity: 1},
                %RS2.Item{id: 1269, quantity: 1}
              ]}

    # update quantity
    assert Container.set_item([%RS2.Item{id: 995, quantity: 1}], 0, 995, 100) ==
             {:ok,
              [
                %RS2.Item{id: 995, quantity: 100}
              ]}

    # invalid slot
    assert Container.set_item(items, 10, 4151, 1, opts) == {:error, items}

    # invalid slot when setting to nil
    assert Container.set_item(items, 10, nil, opts) == {:error, items}
  end

  test "getting total item quantity of id" do
    # stackable items
    stackable_items = [
      %Item{id: 995, quantity: 100}
    ]

    assert Container.total_quantity_of_id(stackable_items, 995) == 100

    # non stackable items
    non_stackable_items = [
      %Item{id: 4151, quantity: 1},
      %Item{id: 4151, quantity: 1},
      %Item{id: 4151, quantity: 1},
      %Item{id: 4151, quantity: 1}
    ]

    assert Container.total_quantity_of_id(non_stackable_items, 4151) == 4

    # don't count irrelevant items
    mixed_items = [
      %Item{id: 995, quantity: 100},
      %Item{id: 4151, quantity: 1}
    ]

    assert Container.total_quantity_of_id(mixed_items, 4151) == 1
  end

  test "inserting item" do
    items = [
      %RS2.Item{id: 1265, quantity: 1},
      %RS2.Item{id: 1267, quantity: 1},
      %RS2.Item{id: 1269, quantity: 1},
      %RS2.Item{id: 1271, quantity: 1},
      nil,
      nil,
      nil,
      nil,
      nil,
      nil
    ]

    opts = %{capacity: 10, always_stack: false}

    # insert to a higher slot
    assert Container.insert(items, 0, 2, opts) ==
             {:ok,
              [
                %RS2.Item{id: 1267, quantity: 1},
                %RS2.Item{id: 1269, quantity: 1},
                %RS2.Item{id: 1265, quantity: 1},
                %RS2.Item{id: 1271, quantity: 1},
                nil,
                nil,
                nil,
                nil,
                nil,
                nil
              ]}

    # insert to a lower slot
    assert Container.insert(items, 3, 1, opts) ==
             {:ok,
              [
                %RS2.Item{id: 1265, quantity: 1},
                %RS2.Item{id: 1271, quantity: 1},
                %RS2.Item{id: 1267, quantity: 1},
                %RS2.Item{id: 1269, quantity: 1},
                nil,
                nil,
                nil,
                nil,
                nil,
                nil
              ]}

    # insert to an empty slot
    assert Container.insert(items, 1, 7, opts) ==
             {:ok,
              [
                %RS2.Item{id: 1265, quantity: 1},
                %RS2.Item{id: 1269, quantity: 1},
                %RS2.Item{id: 1271, quantity: 1},
                nil,
                nil,
                nil,
                nil,
                %RS2.Item{id: 1267, quantity: 1},
                nil,
                nil
              ]}
  end

  test "removing item" do
    opts = %{capacity: 4, always_stack: false}

    items = [
      %RS2.Item{id: 995, quantity: 100},
      %RS2.Item{id: 1267, quantity: 1},
      %RS2.Item{id: 1269, quantity: 1},
      %RS2.Item{id: 1269, quantity: 1}
    ]

    # normal remove first occurence
    assert Container.remove_item(items, 1269, 1, opts) ==
             {:ok,
              [
                %RS2.Item{id: 995, quantity: 100},
                %RS2.Item{id: 1267, quantity: 1},
                nil,
                %RS2.Item{id: 1269, quantity: 1}
              ], [2], 1}

    # remove multiple of non stackable item
    assert Container.remove_item(items, 1269, 2, opts) ==
             {:ok,
              [
                %RS2.Item{id: 995, quantity: 100},
                %RS2.Item{id: 1267, quantity: 1},
                nil,
                nil
              ], [2, 3], 2}

    # remove stackable item
    assert Container.remove_item(items, 995, 50, opts) ==
             {:ok,
              [
                %RS2.Item{id: 995, quantity: 50},
                %RS2.Item{id: 1267, quantity: 1},
                %RS2.Item{id: 1269, quantity: 1},
                %RS2.Item{id: 1269, quantity: 1}
              ], [0], 50}

    # remove non existing item
    assert Container.remove_item(items, 4151, 1, opts) ==
             {:error, items}

    # remove stackable item that doesn't exist
    assert Container.remove_item(items, 4152, 1, opts) ==
             {:error, items}

    # remove stackable item that doesn't exist
    assert Container.remove_item(items, 4152, 1, %{opts | always_stack: true}) ==
             {:error, items}

    # remove too many of an item
    assert Container.remove_item(items, 995, 1000, opts) ==
             {:ok,
              [
                nil,
                %RS2.Item{id: 1267, quantity: 1},
                %RS2.Item{id: 1269, quantity: 1},
                %RS2.Item{id: 1269, quantity: 1}
              ], [0], 100}
  end

  test "remove item from preferred slot" do
    opts = %{capacity: 5, always_stack: false}

    items = [
      %RS2.Item{id: 995, quantity: 100},
      %RS2.Item{id: 1267, quantity: 1},
      %RS2.Item{id: 1269, quantity: 1},
      %RS2.Item{id: 1269, quantity: 1},
      %RS2.Item{id: 1269, quantity: 1}
    ]

    # remove item at slot 3
    assert Container.remove_item(items, 1269, 1, 3, opts) ==
             {:ok,
              [
                %RS2.Item{id: 995, quantity: 100},
                %RS2.Item{id: 1267, quantity: 1},
                %RS2.Item{id: 1269, quantity: 1},
                nil,
                %RS2.Item{id: 1269, quantity: 1}
              ], [3], 1}

    # try to remove item at slot 3 that doesn't match the id
    assert Container.remove_item(items, 1267, 1, 3, opts) ==
             {:ok,
              [
                %RS2.Item{id: 995, quantity: 100},
                nil,
                %RS2.Item{id: 1269, quantity: 1},
                %RS2.Item{id: 1269, quantity: 1},
                %RS2.Item{id: 1269, quantity: 1}
              ], [1], 1}

    # try to remove item at slot at preferred slot for an item that doesn't exist in container
    assert Container.remove_item(items, 4151, 1, 3, opts) ==
             {:error, items}
  end

  test "has room for item" do
    opts = %{capacity: 3, always_stack: false}

    items = [
      %RS2.Item{id: 995, quantity: 1},
      %RS2.Item{id: 1267, quantity: 1},
      nil
    ]

    # has room for non stackable item
    assert Container.has_room_for?(items, 4151, 1, opts) == true

    # make sure there is at least 1 item
    assert Container.has_room_for?(items, 4151, 0, opts) == false

    # doesn't have room for too many non stackable items
    assert Container.has_room_for?(items, 4151, 10, opts) == false

    # has room for multiple non stackable items
    assert Container.has_room_for?(items, 4151, 10, %{opts | capacity: 28}) == true

    # has room for existing stackable item
    assert Container.has_room_for?(items, 995, 1, opts) == true

    # doesn't have room for existing stackable item with quantity too large
    assert Container.has_room_for?(items, 995, 2_147_483_647, opts) == false

    # has room for new stackable item
    assert Container.has_room_for?(items, 4152, 2_147_483_647, opts) == true
  end

  test "clears items from container" do
    opts = %{capacity: 3, always_stack: false}

    items = [
      %RS2.Item{id: 995, quantity: 1},
      %RS2.Item{id: 1267, quantity: 1},
      nil
    ]

    # clear items from container
    assert Container.clear_items(items, opts) == {:ok, [nil, nil, nil]}
  end
end
