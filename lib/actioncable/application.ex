defmodule Actioncable.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc """
  Implementation of Actioncable server. This is compatible with Actioncable JS client.
  This implementation needs REDIS to store every websocket pid (value) into corresponding channel (key).
  For complete setup of this actioncable server, please check complete tutorial in the github page.
  Do not hesitate to write feedback / issue, this is a first version. Thanks.
  """

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: Actioncable.Worker.start_link(arg)
      # {Actioncable.Worker, arg},
      %{
        id: GenservPid,
        start: {GenservPid, :start_link, [%{}]}
      }
    ]

    # See https://hexdocs.pm/elixir/Actioncable.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Actioncable.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
