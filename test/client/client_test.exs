defmodule EliVndbTest.Client do
  use ExUnit.Case, async: true
  doctest EliVndb.Client

  setup_all do
    {:ok, pid} = EliVndb.Client.start_link
    {:ok, client: pid}
  end

  test "get dbstats" do
    {cmd, result} = EliVndb.Client.dbstats

    assert cmd == :dbstats
    expected_keys = ["users",
                     "posts",
                     "threads",
                     "vn",
                     "releases",
                     "tags",
                     "staff",
                     "producers",
                     "chars",
                     "traits"]
    assert Enum.all?(expected_keys, &(Map.has_key?(result, &1)))
  end

  test "try local client with global true" do
    assert {:error, {:already_started, _ }} = EliVndb.Client.start_link(global: true)
  end

  test "try local client with global false" do
    assert {:ok, local} = EliVndb.Client.start_link(global: false)

    global_dbstats = EliVndb.Client.dbstats
    local_dbstats = EliVndb.Client.dbstats(local)

    assert global_dbstats == local_dbstats

    assert :ok = EliVndb.Client.stop(local)
  end

  test "get vn" do
    {cmd, result} = EliVndb.Client.get(type: "vn")

    assert :results == cmd
    assert result["num"] == 10
    assert result["more"] == true
  end

  test "get vn Suisou Ginka no Istoria with id 20471" do
    {cmd, result} = EliVndb.Client.get_vn(filters: "(id = 20471)")

    assert :results == cmd
    assert result["more"] == false

    assert [first | []] = result["items"]
    assert first["title"] == "Suisou Ginka no Istoria"
    assert first["original"] == "水葬銀貨のイストリア"
  end

end
