defmodule Rs2ex.Item.ContainerTest do
  use ExUnit.Case
  alias Rs2ex.Item
  alias Rs2ex.Item.Container

  test "check if item is stackable" do
    assert Container.stackable_item?(995) == true
    assert Container.stackable_item?(4151) == false
  end

  test "adding items with always_stack should override normal item stacking" do
    assert Container.add_item([], 4151, 100, %{capacity: 10, always_stack: true}) ==
             {:ok, [%Item{id: 4151, quantity: 100, slot: 0}]}
  end

  test "adding stackable item with existing stack" do
    opts = %{capacity: 4, always_stack: false}

    items = [
      %Item{id: 995, quantity: 1, slot: 0}
    ]

    # normal case
    assert Container.add_item(items, 995, 500, opts) ==
             {:ok, [%Rs2ex.Item{id: 995, quantity: 501, slot: 0}]}

    # exceeding max quantity
    assert Container.add_item(items, 995, 2_147_483_647, opts) == {:full, items}

    assert Container.add_item(items, 995, 2_147_483_647 - 1, opts) ==
             {:ok, [%Rs2ex.Item{id: 995, quantity: 2_147_483_647, slot: 0}]}
  end

  test "adding stackable item with non existing stack" do
    opts = %{capacity: 4, always_stack: false}

    # normal case
    assert Container.add_item([], 995, 100, opts) ==
             {:ok, [%Item{id: 995, quantity: 100, slot: 0}]}

    # no free slots
    items = [
      %Item{id: 4151, quantity: 1, slot: 0},
      %Item{id: 4151, quantity: 1, slot: 1},
      %Item{id: 4151, quantity: 1, slot: 2},
      %Item{id: 4151, quantity: 1, slot: 3}
    ]

    assert Container.add_item(items, 995, 100, opts) == {:full, items}

    # exceeding max quantity
    assert Container.add_item([], 995, 2_147_483_647 + 1, opts) == {:full, []}

    assert Container.add_item([], 995, 2_147_483_647, opts) ==
             {:ok, [%Rs2ex.Item{id: 995, quantity: 2_147_483_647, slot: 0}]}
  end

  test "adding non stackable item" do
    opts = %{capacity: 4, always_stack: false}

    # adding 2 when at 2 = ok
    # adding 3 when at 2 = full

    # adding max capacity to empty container
    assert Container.add_item([], 4151, 4, opts) ==
             {:ok,
              [
                %Rs2ex.Item{id: 4151, quantity: 1, slot: 0},
                %Rs2ex.Item{id: 4151, quantity: 1, slot: 1},
                %Rs2ex.Item{id: 4151, quantity: 1, slot: 2},
                %Rs2ex.Item{id: 4151, quantity: 1, slot: 3}
              ]}

    # adding to a full container
    full_container = [
      %Rs2ex.Item{id: 4151, quantity: 1, slot: 0},
      %Rs2ex.Item{id: 4151, quantity: 1, slot: 1},
      %Rs2ex.Item{id: 4151, quantity: 1, slot: 2},
      %Rs2ex.Item{id: 4151, quantity: 1, slot: 3}
    ]

    assert Container.add_item(full_container, 4151, 1, opts) == {:full, full_container}

    # adding enough to fill remaining slots
    partial_container = [
      %Rs2ex.Item{id: 4151, quantity: 1, slot: 0},
      %Rs2ex.Item{id: 4151, quantity: 1, slot: 1}
    ]

    assert Container.add_item(partial_container, 4151, 2, opts) == {:ok, full_container}

    # adding too many for the remaining slots
    assert Container.add_item(partial_container, 4151, 3, opts) == {:full, partial_container}
  end

  test "swapping item slots" do
    items = [
      %Rs2ex.Item{id: 1265, quantity: 1, slot: 1},
      %Rs2ex.Item{id: 1267, quantity: 1, slot: 0},
      %Rs2ex.Item{id: 1269, quantity: 1, slot: 2}
    ]

    # normal case
    assert Container.swap(items, 1, 2) ==
             {:ok,
              [
                %Rs2ex.Item{id: 1265, quantity: 1, slot: 2},
                %Rs2ex.Item{id: 1267, quantity: 1, slot: 0},
                %Rs2ex.Item{id: 1269, quantity: 1, slot: 1}
              ]}

    # invalid slot
    assert Container.swap(items, 1, 10) == {:error, items}

    # slot missing
    assert Container.swap(items, 1, 3) == {:error, items}
  end

  test "setting item slots" do
    items = [
      %Rs2ex.Item{id: 1265, quantity: 1, slot: 1},
      %Rs2ex.Item{id: 1267, quantity: 1, slot: 0},
      %Rs2ex.Item{id: 1269, quantity: 1, slot: 2}
    ]

    # normal case
    assert Container.set(items, 1, 4151, 1) ==
             {:ok,
              [
                %Rs2ex.Item{id: 4151, quantity: 1, slot: 1},
                %Rs2ex.Item{id: 1267, quantity: 1, slot: 0},
                %Rs2ex.Item{id: 1269, quantity: 1, slot: 2}
              ]}

    # update quantity
    assert Container.set([%Rs2ex.Item{id: 995, quantity: 1, slot: 0}], 0, 995, 100) ==
             {:ok,
              [
                %Rs2ex.Item{id: 995, quantity: 100, slot: 0}
              ]}

    # invalid slot
    assert Container.set(items, 10, 4151, 1) == {:error, items}
  end

  test "getting total item quantity of id" do
    # stackable items
    stackable_items = [
      %Item{id: 995, quantity: 100, slot: 0}
    ]

    assert Container.total_quantity_of_id(stackable_items, 995) == 100

    # non stackable items
    non_stackable_items = [
      %Item{id: 4151, quantity: 1, slot: 0},
      %Item{id: 4151, quantity: 1, slot: 1},
      %Item{id: 4151, quantity: 1, slot: 2},
      %Item{id: 4151, quantity: 1, slot: 3}
    ]

    assert Container.total_quantity_of_id(non_stackable_items, 4151) == 4

    # don't count irrelevant items
    mixed_items = [
      %Item{id: 995, quantity: 100, slot: 0},
      %Item{id: 4151, quantity: 1, slot: 1}
    ]

    assert Container.total_quantity_of_id(mixed_items, 4151) == 1
  end
end
