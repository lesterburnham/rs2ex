defmodule Rs2ex.Session do
  def send_packet(session, packet) do
    case Registry.lookup(Rs2ex.Xyz, session) do
      [{pid, _}] ->
        GenServer.call(pid, {:send_packet, packet})

      _ ->
        nil
    end
  end
end
