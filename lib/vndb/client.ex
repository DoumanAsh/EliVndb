defmodule EliVndb.Client do
  @moduledoc """
  VNDB API Client Module.

  [VNDB API Refernce](https://vndb.org/d11)

  ## `EliVndb.Client` types

  ### Global
    In order to start global client use `EliVndb.Client.start_link/1` or `EliVndb.Client.start_link/3` without options or with `:global` set to true.

    Since the client registered globally, once client is started, all other API functions will become available.

    As VNDB allows login only once, you need to re-create it anew in order to re-login.
    You can use method `EliVndb.Client.stop/0` to terminate currently running global client.

  ### Local
    In order to start local client use `EliVndb.Client.start_link/1` or `EliVndb.Client.start_link/3` with `:global` set to false.

    To use local client, you'll need to provide its pid in all API calls.

    **NOTE:** VNDB allows only up to 10 clients from the same API. Global client is preferable way to work with VNDB API.

  ## Available commands

  ### dbstats
    Just retrieves statistics from VNDB.

  ### get
    Each get command requires to specify flags & filters.

    Following default values are used by EliVndb:
    * `flags = ["basic"]`
    * `filters = (id >= 1)`

    On success it returns `{:results, %{...}}`

  ### set
    Each set command requires you to provide ID of modified object.

    On success it returns `{:ok, ${...}}`

    **NOTE:** For set commands successful response contains empty payload as of now. You might as well to ignore it.

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

  ##Constants
  @doc "Returns name of global client."
  def global_name, do: @name

  ##Client API
  @typedoc "Client initialization options"
  @type start_options :: [global: boolean()]
  @typedoc "Get command options"
  @type get_options :: [type: iodata(), flags: list(iodata()), filters: iodata(), options: Map.t()]
  @typedoc "Set command options"
  @type set_options :: [type: iodata(), id: integer, fields: Map.t()]

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

  Arguments:
  * `pid` - Client identifier. Global is used as default.

  [Reference](https://vndb.org/d11#4)

  On success returns: `{:dbstats, map()}`
  """
  def dbstats(pid \\ @name) do
    GenServer.call(pid, :dbstats)
  end

  @spec get(get_options(), GenServer.server()) :: term()
  @doc """
  Performs GET command.

  [Reference](https://vndb.org/d11#5)

  Arguments:
  * `options` - Keyword list of command options. See below.
  * `pid` - Client identifier. Global is used as default.

  Options:
  * `:type` - Command type. See VNDB API for possible values.
  * `:flags` - Command flags as array of strings. Possible values depends on `:type`.
  * `:filters` - Command filters as string. Possible values depends on `:type`.
  * `:options` - Command options as map. VNDB API allows following keys: `page: integer`, `results: integer`, `sort: string`, `reverse: boolean`

  Following default values are used by EliVndb:
  * `flags = ["basic"]`
  * `filters = id >= 1`

  On success returns: `{:results, map()}`
  """
  def get(options, pid \\ @name) do
    GenServer.call(pid, {:get, options})
  end

  @spec get_vn(get_options(), GenServer.server()) :: term()
  @doc """
  Performs GET command with vn type.

  The same as `EliVndb.Client.get/2`
  """
  def get_vn(options, pid \\ @name) do
    get(Keyword.put(options, :type, "vn"), pid)
  end

  @spec get_release(get_options(), GenServer.server()) :: term()
  @doc """
  Performs GET command with release type.

  The same as `EliVndb.Client.get/2`
  """
  def get_release(options, pid \\ @name) do
    get(Keyword.put(options, :type, "release"), pid)
  end

  @spec get_producer(get_options(), GenServer.server()) :: term()
  @doc """
  Performs GET command with producer type.

  The same as `EliVndb.Client.get/2`
  """
  def get_producer(options, pid \\ @name) do
    get(Keyword.put(options, :type, "producer"), pid)
  end

  @spec get_character(get_options(), GenServer.server()) :: term()
  @doc """
  Performs GET command with character type.

  The same as `EliVndb.Client.get/2`
  """
  def get_character(options, pid \\ @name) do
    get(Keyword.put(options, :type, "character"), pid)
  end

  @spec get_staff(get_options(), GenServer.server()) :: term()
  @doc """
  Performs GET command with staff type.

  The same as `EliVndb.Client.get/2`
  """
  def get_staff(options, pid \\ @name) do
    get(Keyword.put(options, :type, "staff"), pid)
  end

  @spec get_user(get_options(), GenServer.server()) :: term()
  @doc """
  Performs GET command with user type.

  The same as `EliVndb.Client.get/2`
  """
  def get_user(options, pid \\ @name) do
    get(Keyword.put(options, :type, "user"), pid)
  end

  @spec get_votelist(get_options(), GenServer.server()) :: term()
  @doc """
  Performs GET command with votelist.

  The same as `EliVndb.Client.get/2`
  """
  def get_votelist(options, pid \\ @name) do
    get(Keyword.put(options, :type, "votelist"), pid)
  end

  @spec get_vnlist(get_options(), GenServer.server()) :: term()
  @doc """
  Performs GET command with vnlist type.

  The same as `EliVndb.Client.get/2`
  """
  def get_vnlist(options, pid \\ @name) do
    get(Keyword.put(options, :type, "vnlist"), pid)
  end

  @spec get_wishlist(get_options(), GenServer.server()) :: term()
  @doc """
  Performs GET command with wishlist type.

  The same as `EliVndb.Client.get/2`
  """
  def get_wishlist(options, pid \\ @name) do
    get(Keyword.put(options, :type, "wishlist"), pid)
  end

  @spec set(set_options(), GenServer.server()) :: term()
  @doc """
  Performs SET command.

  [Reference](https://vndb.org/d11#6)

  Arguments:
  * `options` - Keyword list of command options. See below.
  * `pid` - Client identifier. Global is used as default.

  Options:
  * `:type` - Command type. See VNDB API for possible values.
  * `:id` - Identifier of object on which to perform SET.
  * `:fields` - Map of object's field to its new value.
  """
  def set(options, pid \\ @name) do
    GenServer.call(pid, {:set, options})
  end

  @spec set_votelist(set_options(), GenServer.server()) :: term()
  @doc """
  Performs SET command with votelist type.

  The same as `EliVndb.Client.set/2`
  """
  def set_votelist(options, pid \\ @name) do
    set(Keyword.put(options, :type, "votelist"), pid)
  end

  @spec set_vnlist(set_options(), GenServer.server()) :: term()
  @doc """
  Performs SET command with votelist type.

  The same as `EliVndb.Client.set/2`
  """
  def set_vnlist(options, pid \\ @name) do
    set(Keyword.put(options, :type, "vnlist"), pid)
  end

  @spec set_wishlist(set_options(), GenServer.server()) :: term()
  @doc """
  Performs SET command with votelist type.

  The same as `EliVndb.Client.set/2`
  """
  def set_wishlist(options, pid \\ @name) do
    set(Keyword.put(options, :type, "wishlist"), pid)
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

  def handle_call({:get, args}, from, %{queue: queue} = state) do
    msg = vndb_msg("get #{args[:type]} #{get_flags(args)} #{get_filters(args)} #{get_options(args)}")

    Logger.info fn -> 'Send get vn=#{msg}' end
    :ok = :ssl.send(state.socket, msg)

    {:noreply, Map.put(state, :queue, :queue.in(from, queue))}
  end

  def handle_call({:set, args}, from, %{queue: queue} = state) do
    msg = vndb_msg("set #{args[:type]} #{args[:id]} #{set_fields(args)}")

    Logger.info fn -> 'Send set vn=#{msg}' end
    :ok = :ssl.send(state.socket, msg)

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
    case String.split(String.trim_trailing(msg, @msg_end), " ", parts: 2) do
      [name] -> {String.to_atom(name), %{}} # For consistency sake let's return empty map.
      [name, value] -> {String.to_atom(name), Poison.decode!(value)}
    end
  end

  @spec vndb_msg(String.t()) :: String.t()
  defp vndb_msg(command) do command <> @msg_end end

  @spec vndb_msg(String.t(), map()) :: String.t()
  defp vndb_msg(command, args) do "#{command} #{Poison.encode!(args)}" <> @msg_end end

  # Login utils
  @spec login_args(nil, nil) :: map()
  defp login_args(nil, nil) do @login_args end

  @spec login_args(String.t(), String.t()) :: map()
  defp login_args(username, password) do
    Map.merge(@login_args, %{username: username, password: password})
  end

  # Get utils
  @spec get_flags(Map.t()) :: binary()
  defp get_flags(args) do
    case Keyword.get(args, :flags) do
      nil -> "basic"
      flags -> Enum.join(flags, ",")
    end
  end

  @spec get_filters(Map.t()) :: binary()
  defp get_filters(args) do
    case Keyword.get(args, :filters) do
      nil -> "(id >= 1)"
      filters -> filters
    end
  end

  @spec get_options(Map.t()) :: iodata()
  defp get_options(args) do
    case Keyword.get(args, :options) do
      nil -> ""
      %{} -> ""
      opts -> Poison.encode!(opts)
    end
  end

  # Set utils
  @spec set_fields(Map.t()) :: iodata()
  defp set_fields(args) do
    case Keyword.get(args, :fields) do
      nil -> ""
      %{} -> ""
      opts -> Poison.encode!(opts)
    end
  end
end

