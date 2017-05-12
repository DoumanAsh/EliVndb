defmodule EliVndbTest.Filters do
  use ExUnit.Case
  doctest EliVndb.Filters

  import EliVndb.Filters

  test "sigil filter creation" do
    assert ~f(search ~ Sokoku) == "(search ~ Sokoku)"
  end

  test "create simple filters with and" do
    assert filters(id = 7 and id = 8) == "(id = 7 and id = 8)"
  end
end

