defmodule Actioncable.MixProject do
  use Mix.Project

  def project do
    [
      app: :actioncable,
      version: "0.1.3",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Actioncable.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp description do
    """
    It's like ActionCable (100% compatible with JS Client), but you know, for Elixir
    """
  end

  defp package do
    [
      links: %{"GitHub" => "https://github.com/cedricPoncot/actioncable"},
      licenses: ["MIT"]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4.10"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:redix, "~> 1.1.3"},
      {:poison, ">= 0.0.0"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
    ]
  end
end
