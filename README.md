# Actioncable

## Installation

### - 1) Add the `:actioncable` dependency to your mix.exs file

```elixir
defp deps() do
  [
    {:actioncable, "~> 0.1.0"}
  ]
```

Then, run `mix deps.get` in your shell to fetch the new dependencies.


### - 2) Add this configuration in config/config.ex,

```elixir
config :your_application_name, Your_application_name_Web.Endpoint,
  check_origin: false,
    http: [
      dispatch: [
        {:_, [
          {"/cable", SocketHandler, []},
          {:_, Phoenix.Endpoint.Cowboy2Handler, {Your_application_name_Web.Endpoint, []}}
        ]}
      ]
    ],
    subprotocols: ["actioncable-v1-json"]
```

It will redirect every url ending by "/cable" to Cowboy Websocket Handler.
Other url will be redirect in your Endpoint as usual.

### - 3) Create module : `Your_application_name_Web.SocketHandler`

```elixir
defmodule SocketHandler do
  use Actioncable.SocketHandler

  def handle_client_message(message) do
    #Handle message from JS client the way you want it ;)
    IO.inspect message
  end

end

```

This module has to `use Actioncable.SocketHandler`and implement `handle_client_message`function.


### - 4) Start a Redix connection named `:redix_ac`
(it will be used for storing websocket pid in corresponding channel.)

In your application.ex :

```elixir
def start(_type, _args) do
  children = [
    %{
      id: Redix,
      start: {Redix, :start_link, ["redis://localhost:6379/15", [name: :redix_ac]]}
    }
  ]
end
```

Note: in this case, i'm using redis database number 15. If the server shut down brutally, you may want to clean the different channel.
You can do the following (You have to be sure that your redis database -in this case the redis database 15-  does not store any other data) :

```elixir
def start(_type, _args) do
  children = [
    %{
      id: Redix,
      start: {Redix, :start_link, ["redis://localhost:6379/15", [name: :redix_ac]]}
    }
  ]
  opts = [strategy: :one_for_one, name: XXX.Supervisor]
  ret = XXX.start_link(children, opts)
  Redix.command!(:redix_ac, ["flushdb"])
  ret
end
```

It will clean redis database 15 at every start.

### Usage

- Receive message : As seen above, every message will be transfered in this function : `handle_client_message(message)` (In `SocketHandler` module)

- Send message : use `Actioncable.Channel.broadcast(channel, message)` See doc in hex.pm for this function


### Improvement

- Do not hesitate to perform pull request, this is a first version and there are a lot of things that need to be improved