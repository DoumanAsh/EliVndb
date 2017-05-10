# EliVndb

Kawaii VNDB API for Elixir

## Design

Currently it is designed as global GenServer that requires to be initiated once through `Vndb.Client.start_link()`

## Installation

```elixir
def deps do
  [{:vndb, "~> 0.1.0"}]
end
```
