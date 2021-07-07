defmodule Actioncable.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: Actioncable.Worker.start_link(arg)
      # {Actioncable.Worker, arg},
      %{
        id: Redix,
        start: {Redix, :start_link, ["redis://localhost:6379/15", [name: :redix]]}
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Actioncable.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
