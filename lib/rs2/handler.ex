defmodule RS2.Handler do
  require Logger

  alias RS2.{CommandEncoder, ResponseDecoder, Packet}
  alias RS2.Packet.Overflow
  alias RS2.Tick.{PlayerUpdate}

  use GenServer
  use Bitwise

  @behaviour :ranch_protocol

  @opcode_game 14
  @opcode_update 15
  @opcode_player_count 16
  @packet_sizes Code.eval_string("""
                  [
                    0, 0, 0, 1, -1, 0, 0, 0, 0, 0, # 0
                    0, 0, 0, 0, 8, 0, 6, 2, 2, 0,  # 10
                    0, 2, 0, 6, 0, 12, 0, 0, 0, 0, # 20
                    0, 0, 0, 0, 0, 8, 4, 0, 0, 2,  # 30
                    2, 6, 0, 6, 0, -1, 0, 0, 0, 0, # 40
                    0, 0, 0, 12, 0, 0, 0, 8, 0, 0, # 50
                    0, 8, 0, 0, 0, 0, 0, 0, 0, 0,  # 60
                    6, 0, 2, 2, 8, 6, 0, -1, 0, 6, # 70
                    0, 0, 0, 0, 0, 1, 4, 6, 0, 0,  # 80
                    0, 0, 0, 0, 0, 3, 0, 0, -1, 0, # 90
                    0, 13, 0, -1, 0, 0, 0, 0, 0, 0,# 100
                    0, 0, 0, 0, 0, 0, 0, 6, 0, 0,  # 110
                    1, 0, 6, 0, 0, 0, -1, 0, 2, 6, # 120
                    0, 4, 6, 8, 0, 6, 0, 0, 0, 2,  # 130
                    0, 0, 0, 0, 0, 6, 0, 0, 0, 0,  # 140
                    0, 0, 1, 2, 0, 2, 6, 0, 0, 0,  # 150
                    0, 0, 0, 0, -1, -1, 0, 0, 0, 0,# 160
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  # 170
                    0, 8, 0, 3, 0, 2, 0, 0, 8, 1,  # 180
                    0, 0, 12, 0, 0, 0, 0, 0, 0, 0, # 190
                    2, 0, 0, 0, 0, 0, 0, 0, 4, 0,  # 200
                    4, 0, 0, 0, 7, 8, 0, 0, 10, 0, # 210
                    0, 0, 0, 0, 0, 0, -1, 0, 6, 0, # 220
                    1, 0, 0, 0, 6, 0, 6, 8, 1, 0,  # 230
                    0, 4, 0, 0, 0, 0, -1, 0, -1, 4,# 240
                    0, 0, 6, 6, 0, 0, 0            # 250
                  ]
                """)
                |> elem(0)

  def start_link(ref, socket, transport, _opts) do
    peername = stringify_peername(socket)
    pid = :proc_lib.spawn_link(__MODULE__, :init, [ref, socket, transport])
    Logger.info("accepted connection from: #{peername}")
    {:ok, pid}
  end

  defp stringify_peername(socket) do
    {:ok, {addr, port}} = :inet.peername(socket)

    address =
      addr
      |> :inet_parse.ntoa()
      |> to_string()

    "#{address}:#{port}"
  end

  def init(init_arg) do
    # RS2.Xyz |> Registry.register(1, {})
    {:ok, init_arg}
  end

  def init(ref, socket, transport) do
    :ok = :ranch.accept_ack(ref)
    :ok = transport.setopts(socket, [{:active, true}])

    :gen_server.enter_loop(__MODULE__, [], %{
      socket: socket,
      transport: transport,
      buffer: <<>>,
      status: :opcode,
      server_key: nil,
      login_size: nil,
      enc_size: nil,
      in_cipher: nil,
      out_cipher: nil,
      popcode: -1,
      psize: -1
    })
  end

  def handle_info(
        {:tcp, _socket, data},
        %{buffer: buffer} = state
      ) do
    if byte_size(data) > 0 do
      process_buffer(%{state | buffer: buffer <> data})
    else
      {:noreply, state}
    end
  end

  def handle_info({:tcp_closed, socket}, %{socket: socket, transport: transport} = state) do
    transport.close(socket)
    {:stop, :normal, state}
  end

  @doc false
  def handle_call({:send_packet, %Packet{} = packet}, _, state) do
    send_packet(state, packet)

    {:reply, :ok, state}
  end

  defp process_buffer(%{status: :opcode, buffer: buffer} = state) do
    if byte_size(buffer) >= 1 do
      <<opcode, _rest::binary>> = buffer

      process_opcode(opcode, state)
    else
      {:noreply, state}
    end
  end

  defp process_buffer(
         %{status: :login, socket: socket, transport: transport, buffer: buffer} = state
       ) do
    if byte_size(buffer) >= 1 do
      <<_name_hash, rest::binary>> = buffer

      server_key = :rand.uniform(1 <<< 32)

      transport.send(socket, <<0::64, 0, server_key::64>>)

      process_buffer(%{state | status: :precrypted, buffer: rest, server_key: server_key})
    else
      {:noreply, state}
    end
  end

  defp process_buffer(
         %{status: :precrypted, socket: socket, transport: transport, buffer: buffer} = state
       ) do
    if byte_size(buffer) >= 2 do
      <<login_opcode::unsigned, login_size::unsigned, rest::binary>> = buffer

      enc_size = login_size - (36 + 1 + 1 + 2)

      cond do
        not Enum.member?([16, 18], login_opcode) ->
          Logger.warn("invalid login opcode: #{login_opcode}")
          transport.close(socket)
          {:stop, :normal, state}

        enc_size < 1 ->
          Logger.warn("encrypted packet size zero or negative: #{enc_size}")
          transport.close(socket)
          {:stop, :normal, state}

        true ->
          process_buffer(%{
            state
            | status: :crypted,
              buffer: rest,
              login_size: login_size,
              enc_size: enc_size
          })
      end
    else
      {:noreply, state}
    end
  end

  defp process_buffer(
         %{
           status: :crypted,
           socket: socket,
           transport: transport,
           buffer: buffer,
           login_size: login_size,
           enc_size: enc_size,
           server_key: server_key
         } = state
       ) do
    if byte_size(buffer) >= login_size do
      <<
        magic::unsigned,
        version::16-unsigned,
        _low_memory::unsigned,
        _padding::288,
        reported_size::unsigned,
        block_opcode::unsigned,
        client_k1::32,
        client_k2::32,
        server_k1::32,
        server_k2::32,
        _uid::32,
        credentials::binary
      >> = buffer

      [username, password, _rest] = :binary.split(credentials, "\n", [:global])

      reported_server_key = server_k1 <<< 32 ||| server_k2

      cond do
        magic != 255 ->
          Logger.warn("incorrect magic ID: #{magic}")
          transport.close(socket)
          {:stop, :normal, state}

        version != 317 ->
          Logger.warn("incorrect client version: #{version}")
          transport.send(socket, <<6>>)
          transport.close(socket)
          {:stop, :normal, state}

        reported_size != enc_size - 1 ->
          Logger.warn(
            "packet size mismatch (expected: #{enc_size - 1}, reported: #{reported_size})"
          )

          transport.close(socket)
          {:stop, :normal, state}

        block_opcode != 10 ->
          Logger.warn("invalid login block opcode: #{block_opcode}")
          transport.close(socket)
          {:stop, :normal, state}

        reported_server_key != server_key ->
          Logger.warn(
            "server key mismatch (expected: #{server_key}, reported: #{reported_server_key})"
          )

          transport.send(socket, <<10>>)
          transport.close(socket)
          {:stop, :normal, state}

        not RS2.Player.Username.valid_name?(username) ->
          Logger.warn("invalid username: #{username}")
          transport.send(socket, <<11>>)
          transport.close(socket)
          {:stop, :normal, state}

        username != "mopar" || password != "bob" ->
          Logger.warn("invalid username or password")
          transport.send(socket, <<3>>)
          transport.close(socket)
          {:stop, :normal, state}

        true ->
          session_key =
            Enum.map([client_k1, client_k2, server_k1, server_k2], fn x -> Overflow.int(x) end)

          in_cipher = session_key |> Isaac.init()
          out_cipher = session_key |> Enum.map(fn x -> x + 50 end) |> Isaac.init()

          transport.send(socket, <<2, 2, 0>>)

          state = %{state | out_cipher: out_cipher, in_cipher: in_cipher}

          player = %RS2.Player{
            index: 1,
            member: true,
            location: %RS2.Location{x: 3222, y: 3218, z: 0}
          }

          # xxx use corrected username
          Registry.register(RS2.Xyz, username, %{})

          RS2.Container.Server.start_link({username, :equipment}, 14, false, [
            {RS2.Container.Hook.Interface, %{interface_id: 1688}}
          ])

          RS2.Container.Server.start_link({username, :inventory}, 28, false, [
            {RS2.Container.Hook.Interface, %{interface_id: 3214}}
          ])

          RS2.Container.Server.start_link({username, :bank}, 352, true, [])

          send_packet(state, CommandEncoder.initialize_player(player))

          send_packet(state, CommandEncoder.reset_camera())

          send_packet(state, CommandEncoder.send_message("Welcome to RS2."))

          send_packet(state, CommandEncoder.load_map_region(player.location))

          send_packet(state, CommandEncoder.display_player_option("Trade", 2, true))

          send_packet(state, CommandEncoder.display_player_option("Follow", 3, true))

          send_packet(state, PlayerUpdate.build(player))

          Enum.each(CommandEncoder.send_sidebar_interfaces(), &send_packet(state, &1))

          send_packet(state, CommandEncoder.friend_server_status(2))

          process_buffer(%{
            state
            | status: :authenticated,
              buffer: <<>>,
              in_cipher: in_cipher,
              out_cipher: out_cipher
          })
      end
    else
      {:noreply, state}
    end
  end

  defp process_buffer(
         %{
           status: :authenticated,
           buffer: buffer,
           psize: psize,
           popcode: popcode,
           in_cipher: in_cipher
         } = state
       ) do
    if popcode == -1 do
      if byte_size(buffer) >= 1 do
        <<opcode, rest::binary>> = buffer

        random = Isaac.next_int(in_cipher)
        random_byte = random &&& 0xFF
        popcode = opcode - random_byte &&& 0xFF
        psize2 = Enum.at(@packet_sizes, popcode)

        process_buffer(%{state | popcode: popcode, psize: psize2, buffer: rest})
      else
        {:noreply, state}
      end
    else
      if psize == -1 do
        if byte_size(buffer) >= 1 do
          <<size, rest::binary>> = buffer

          process_buffer(%{state | psize: size, buffer: rest})
        else
          {:noreply, state}
        end
      else
        if byte_size(buffer) >= psize do
          <<packet::binary-size(psize), rest::binary>> = buffer

          receive_packet(%Packet{
            opcode: popcode,
            payload: packet,
            type: if(Enum.at(@packet_sizes, popcode) == -1, do: :var8, else: :fixed)
          })

          process_buffer(%{state | psize: -1, popcode: -1, buffer: rest})
        else
          {:noreply, state}
        end
      end
    end
  end

  defp process_buffer(%{status: status} = state) do
    Logger.warn("unhandled status: #{status}")
    {:noreply, state}
  end

  defp process_opcode(@opcode_game, %{buffer: buffer} = state) do
    Logger.info("Connection type: client")
    <<_opcode, rest::binary>> = buffer
    process_buffer(%{state | status: :login, buffer: rest})
  end

  defp process_opcode(@opcode_update, state) do
    Logger.info("Connection type: update")
    {:noreply, state}
  end

  defp process_opcode(@opcode_player_count, %{socket: socket, transport: transport} = state) do
    Logger.info("Connection type: online")
    :ok = :gen_tcp.send(socket, "test")
    transport.close(socket)
    {:noreply, state}
  end

  defp process_opcode(opcode, %{socket: socket, transport: transport} = state) do
    Logger.warn("invalid opcode: #{opcode}")
    transport.close(socket)
    {:stop, :normal, state}
  end

  defp receive_packet(%Packet{opcode: _opcode, payload: _payload} = packet) do
    # Logger.debug(
    #   "recv packet (opcode: #{opcode}, payload: #{inspect(payload, [{:binaries, :as_binaries}, {:limit, :infinity}])})"
    # )

    task =
      Task.async(fn ->
        ResponseDecoder.decode(packet)
      end)

    Task.await(task)
  end

  defp send_packet(
         %{socket: socket, transport: transport, out_cipher: out_cipher},
         %RS2.Packet{opcode: opcode, type: type, payload: payload}
       ) do
    random = Isaac.next_int(out_cipher)
    random_byte = random &&& 0xFF
    new_opcode = opcode + random_byte

    packet_frame = <<new_opcode>> <> packet_size_header(type, byte_size(payload)) <> payload

    # Logger.debug(
    #   "send packet (opcode: #{opcode}, payload: #{inspect(payload, [{:binaries, :as_binaries}, {:limit, :infinity}])})"
    # )

    transport.send(socket, packet_frame)
  end

  defp packet_size_header(:var8, size), do: <<size>>
  defp packet_size_header(:var16, size), do: <<size >>> 8, size>>
  defp packet_size_header(:fixed, _size), do: <<>>
end
