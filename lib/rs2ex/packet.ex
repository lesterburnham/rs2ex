defmodule Rs2ex.Packet do
  defstruct [:opcode, type: :fixed, payload: <<>>]
end
