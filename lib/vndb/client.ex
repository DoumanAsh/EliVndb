defmodule EliVndb.Client do
  @moduledoc """
  VNDB API Client Module.

  [VNDB API Refernce](https://vndb.org/d11)

  There are two ways to work with `EliVndb.Client`

  ## Global
    In order to start global client use `EliVndb.Client.start_link/1` or `EliVndb.Client.start_link/3` without options or with `:global` set to true.

    Since the client registered globally, once client is started, all other API functions will become available.

    As VNDB allows login only once, you need to re-create it anew in order to re-login.
    You can use method `EliVndb.Client.stop/0` to terminate currently running global client.

  ## Local
    In order to start local client use `EliVndb.Client.start_link/1` or `EliVndb.Client.start_link/3` with `:global` set to false.

    To use local client, you'll need to provide its pid in all API calls.

    **NOTE:** VNDB allows only up to 10 clients from the same API. Global client is preferable way to work with VNDB API.

  ## Result
    Each function that returns map will has keys as strings.
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
  @typedoc "Client initialization options"
  @type start_options :: [global: boolean()]

  @spec start_link(start_options()) :: GenServer.on_start()
  @doc """
  Starts VNDB API Client without authorization.

  Note that some VNDB APIs may require you to provide login/password.

  Options:
    * `:global` - whether to register client globally.
  """
  def start_link(opts \\ []) do
    start_link(nil, nil, opts)
  end

  @spec start_link(binary | nil, binary | nil, start_options()) :: GenServer.on_start()
  @doc """
  Starts VNDB API Client with provided credentials.

  Parameters:
    * `user` - Username to use for login. To omit provide `nil`
    * `password` - Password to use for login. To omit provide `nil`

  Options:
    * `:global` - whether to register client globally.
  """
  def start_link(user, password, opts \\ []) do
    initial_state = Map.merge(@initial_state, %{user: user, password: password})

    case Keyword.get(opts, :global, true) do
      true -> GenServer.start_link(__MODULE__, initial_state, name: @name)
      false -> GenServer.start_link(__MODULE__, initial_state)
    end
  end

  @spec stop(GenServer.server()) :: :ok
  @doc """
  Stops particular client
  """
  def stop(pid) do
    GenServer.stop(pid)
  end

  @spec stop() :: :ok
  @doc """
  Stops global client.

  Does nothing if client hasn't been started.
  """
  def stop() do
    case GenServer.whereis(@name) do
      nil -> :ok
      _ -> stop(@name)
    end
  end

  @spec dbstats(GenServer.server()) :: term()
  @doc """
  Retrieves VNDB stats using particular client.

  [Reference](https://vndb.org/d11#4)

  On success returns: `{:dbstats, map()}`
  """
  def dbstats(pid) do
    GenServer.call(pid, :dbstats)
  end

  @spec dbstats() :: term()
  @doc """
  Retrieves VNDB stats using global client.

  See `EliVndb.Client.dbstats/1`
  """
  def dbstats() do
    dbstats(@name)
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
    {String.to_atom(name), Poison.decode!(value)}
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

