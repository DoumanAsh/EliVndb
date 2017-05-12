defmodule EliVndb.Filters do
  @moduledoc """
  Utilities to create filters for VNDB API

  ## Examples

  ### Using filters macros

  ```elixir
    iex> require EliVndb.Filters
    iex> EliVndb.Filters.filters(id = 5)
    "(id = 5)"

  ```

  ### Using filters sigil

  ```elixir
    iex> import EliVndb.Filters
    iex> ~f(id = 5 and id = 6)
    "(id = 5 and id = 6)"

  ```
  """

  @doc "Returns suitable filters expression in format `(term)`"
  defmacro sigil_f(term, []) do
    quote do
      "(#{unquote(term)})"
    end
  end

  @doc """
  Wraps Elixir expression as filters `(expr)`

  It is useful when VNDB filter can be expressed through Elixir syntax.

  Note that some allowed symbols like `*` or `~` cannot be passed as it is not valid syntax.
  In such case use sigil `~f` which basically wraps your expression into string without any check.

  """
  defmacro filters(expr) do
    sigil_f(Macro.to_string(expr), [])
  end
end

