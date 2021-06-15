defmodule Rs2ex.ResponseDecoder do
  require Logger
  alias Rs2ex.Packet

  @ignore_opcodes Code.eval_string("""
                  [
                  0, 77, 78, 3, 226, 148, 36,
                  246, 165, 121, 150, 238, 183,
                  230, 136, 189, 152, 200, 85
                  ]
                  """)
                  |> elem(0)

  # enter new region
  def decode(%Packet{opcode: 210}) do
    Logger.info("enter new region")
  end

  # ignore
  def decode(%Packet{opcode: opcode}) when opcode in @ignore_opcodes do
  end

  def decode(%Packet{opcode: opcode, payload: payload}) do
    Logger.warn(
      "unhandled packet (opcode: #{opcode}, payload: #{inspect(payload, [{:binaries, :as_binaries}, {:limit, :infinity}])})"
    )
  end
end
