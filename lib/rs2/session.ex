defmodule RS2.Session do
  def send_packet(session, packet) do
    Task.start(fn ->
      case Registry.lookup(RS2.Xyz, session) do
        [{pid, _}] ->
          GenServer.call(pid, {:send_packet, packet})

        _ ->
          nil
      end
    end)
  end
end
