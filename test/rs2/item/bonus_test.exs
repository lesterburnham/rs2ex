defmodule RS2.Item.BonusTest do
  use ExUnit.Case
  alias RS2.Item
  alias RS2.Item.Hook.Bonus

  test "calculate bonus" do
    items = [
      %Item{id: 1149, quantity: 1},
      %Item{id: 3140, quantity: 1},
      %Item{id: 4087, quantity: 1},
      %Item{id: 1187, quantity: 1},
      %Item{id: 4587, quantity: 1}
    ]

    assert Bonus.build_bonus_text(items) == [
             "Stab: +8",
             "Slash: +67",
             "Crush: -2",
             "Magic: -39",
             "Range: -8",
             "Stab: +182",
             "Slash: +195",
             "Crush: +193",
             "Magic: -8",
             "Range: +181",
             "Strength: +66",
             "Prayer: +0"
           ]
  end
end
