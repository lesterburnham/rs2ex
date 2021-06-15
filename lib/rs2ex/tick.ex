defmodule Rs2ex.Tick do
  use GenServer
  require Logger
  alias Rs2ex.{Player, Npc}
  alias Rs2ex.Tick.{PlayerUpdate}

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(state) do
    :timer.send_interval(600, :tick)
    {:ok, state}
  end

  def handle_info(:tick, state) do
    npcs = [%Npc{index: 0}, %Npc{index: 1}, %Npc{index: 2}]

    players = [
      %Player{
        index: 1,
        member: true,
        location: %Rs2ex.Location{x: 3222, y: 3218, z: 0}
      }
    ]

    tick_stream = Task.async_stream(npcs ++ players, &tick_task/1)
    update_stream = Task.async_stream(players, &update_task/1)
    reset_stream = Task.async_stream(npcs ++ players, &reset_task/1)

    Stream.run(tick_stream)
    Stream.run(update_stream)
    Stream.run(reset_stream)

    {:noreply, state}
  end

  defp tick_task(%Npc{index: _index}) do
    # Logger.debug("npc tick #{index}")
    nil
  end

  defp tick_task(%Player{index: _index}) do
    # Logger.debug("player tick #{index}")
    nil
  end

  defp update_task(%Player{index: _index} = player) do
    # Logger.debug("player update #{index}")
    # player update
    # npc update

    # {pid, _} = Registry.lookup(Rs2ex.Xyz, "mopar")

    case Registry.lookup(Rs2ex.Xyz, "mopar") do
      [{pid, _}] ->
        # IO.puts "got pid for mopar"
        # IO.inspect pid

        # Process.send(pid, message, [])

        # test a crash here... (pid)
        # crashes the entire app if the genserver call errors

        GenServer.call(pid, {:send_packet, PlayerUpdate.build(player)})

      _ ->
        nil
    end
  end

  defp reset_task(%Npc{index: _index}) do
    # Logger.debug("npc reset #{index}")
    nil
  end

  defp reset_task(%Player{index: _index}) do
    # Logger.debug("player reset #{index}")
    nil
  end
end
