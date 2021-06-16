defmodule Rs2ex.Item do
  @enforce_keys [:id]
  defstruct [:id, :slot, quantity: 1]
end

# defimpl Inspect, for: Rs2ex.Item do
#   def inspect(%Rs2ex.Item{id: id, slot: slot, quantity: quantity}, _opts) do
#     "[id=#{id}, slot=#{slot} quantity=#{quantity}]"
#   end
# end
