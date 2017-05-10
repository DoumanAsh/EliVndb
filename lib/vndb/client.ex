defmodule EliVndb.Client do
  @moduledoc """
  VNDB API Client

  Once client is started, all other API functions will become available.
  As VNDB allows login only once, you need to re-create it anew in order to re-login.
  """
  require Logger
  @behaviour GenServer
  use GenServer

  @name __MODULE__

  @host 'api.vndb.org'
  #@port 19_534
  @ssl_port 19_535
  @default_opts  [:binary, active: false, reuseaddr: true]
  @initial_state  %{socket: nil, queue: :queue.new()}

  @login_args  %{protocol: 1, client: "eli", clientver: "0.1"}

  # All VNDB messages end with this byte
  @msg_end <<4>>

  ##Client API

  @spec start_link() :: GenServer.on_start()
  @doc """
  Starts VNDB API Client without authorization.

  Note that some VNDB APIs may require you to provide login/password.
  """
  def start_link() do
    start_link(nil, nil)
  end

  @spec start_link(any(), any()) :: GenServer.on_start()
  @doc """
  Starts VNDB API Client with provided credentials.
  """
  def start_link(user, password) do
    GenServer.start_link(__MODULE__, Map.merge(@initial_state, %{user: user, password: password}), name: @name)
  end

  @spec stop() :: :ok
  @doc """
  Stops client.

  Does nothing if client hasn't been started.
  """
  def stop() do
    case GenServer.whereis(@name) do
      nil -> :ok
      _ -> GenServer.stop(@name)
    end
  end

  @spec dbstats() :: term()
  @doc """
  Retrieves VNDB stats.
  """
  def dbstats() do
    GenServer.call(@name, :dbstats)
  end

  ## Server callbacks
  def init(state) do
    Logger.info 'Connect to VNDB'
    {:ok, socket} = :ssl.connect(@host, @ssl_port, @default_opts, :infinity)

    login_args = login_args(state.user, state.password)
    msg = vndb_msg("login", login_args)

    Logger.info fn -> 'Send login=#{msg}' end
    :ok = :ssl.send(socket, msg)
    {:ok, data} = :ssl.recv(socket, 0)
    Logger.info fn -> 'Login response=#{data}' end

    :ssl.setopts(socket, active: true)

    {:ok, %{state | socket: socket}}
  end

  def handle_call(:dbstats, from, %{queue: queue} = state) do
    :ok = :ssl.send(state.socket, vndb_msg("dbstats"))

    {:noreply, Map.put(state, :queue, :queue.in(from, queue))}
  end

  def handle_info({:ssl, _socket, msg}, %{queue: queue} = state) do
    {{:value, client}, new_queue} = :queue.out(queue)

    Logger.info fn -> "VNDB message=#{msg}" end

    result = vndb_msg_parse(msg)
    GenServer.reply(client, result)

    {:noreply, Map.put(state, :queue, new_queue)}
  end

  def handle_info(msg, _state) do
    Logger.warn fn -> "Received unhandled message=#{msg}" end
  end

  ## Utils
  @spec vndb_msg_parse(String.t()) :: tuple()
  defp vndb_msg_parse(msg) do
    [name, value] = String.split(String.trim_trailing(msg, @msg_end), " ", parts: 2)
    {name, Poison.decode!(value)}
  end

  @spec vndb_msg(String.t()) :: String.t()
  defp vndb_msg(command) do command <> @msg_end end

  @spec vndb_msg(String.t(), map()) :: String.t()
  defp vndb_msg(command, args) do "#{command} #{Poison.encode!(args)}" <> @msg_end end

  @spec login_args(nil, nil) :: map()
  defp login_args(nil, nil) do @login_args end

  defp login_args(username, password) do
    Map.merge(@login_args, %{username: username, password: password})
  end
end

