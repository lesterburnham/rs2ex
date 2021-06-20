defmodule RS2.Player.ChatMessage do
  @enforce_keys [:color, :effects, :text]
  defstruct [:color, :effects, :text]
end
