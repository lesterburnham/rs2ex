defmodule RS2.Container.Item do
  @enforce_keys [:id]
  defstruct [:id, quantity: 1]
end
