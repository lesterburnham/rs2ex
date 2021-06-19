defmodule Rs2ex.Item do
  @enforce_keys [:id]
  defstruct [:id, quantity: 1]
end

# defimpl Inspect, for: Rs2ex.Item do
#   def inspect(%Rs2ex.Item{id: id, quantity: quantity}, _opts) do
#     "[id=#{id}, quantity=#{quantity}]"
#   end
# end
