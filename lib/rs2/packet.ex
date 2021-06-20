defmodule RS2.Packet do
  defstruct [:opcode, type: :fixed, payload: <<>>]
end
