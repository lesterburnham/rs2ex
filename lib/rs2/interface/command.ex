defmodule RS2.Interface.Command do
  alias RS2.{CommandEncoder, Session}

  def handle_command(session, command, args)

  def handle_command(session, "item", args) do
    case args do
      [_id] ->
        handle_command(session, "item", args ++ ["1"])

      [id, quantity] ->
        RS2.Container.Server.add_item(
          {session, :inventory},
          id |> String.to_integer(),
          quantity |> String.to_integer()
        )

      _ ->
        session |> Session.send_packet(CommandEncoder.send_message("Usage: ::item id quantity"))
        session |> Session.send_packet(CommandEncoder.send_message("    OR ::item id"))
    end
  end

  def handle_command(session, "bank", _args) do
    session |> Session.send_packet(RS2.Interface.Packets.send_interface_inventory(5292, 5063))
  end

  def handle_command(session, "closeinterface", _args) do
    session |> Session.send_packet(RS2.Interface.Packets.clear_screen())
  end

  def handle_command(session, command, _) do
    session |> Session.send_packet(CommandEncoder.send_message("Unhandled command: #{command}"))
  end
end
