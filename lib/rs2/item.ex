defmodule RS2.Item do
  @enforce_keys [:id]
  defstruct [:id, quantity: 1]
end

# defimpl Inspect, for: RS2.Item do
#   def inspect(%RS2.Item{id: id, quantity: quantity}, _opts) do
#     "[id=#{id}, quantity=#{quantity}]"
#   end
# end
