# EliVndb

Kawaii VNDB API for Elixir

[VNDB API Refernce](https://vndb.org/d11)

## EliVndb.Client types

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
* `filters = id >= 1`

On success it returns `{:results, %{...}}`

### set
Each set command requires you to provide ID of modified object.

On success it returns `{:ok, ${...}}`

**NOTE:** For set commands successful response contains empty payload as of now. You might as well to ignore it.

## Installation

```elixir
def deps do
  [{:vndb, "~> 0.1.0"}]
end
```
