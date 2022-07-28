defmodule Farside.MixProject do
  use Mix.Project

  def project do
    [
      app: :farside,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Farside.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.8"},
      {:jason, "~> 1.1"},
      {:plug_attack, "~> 0.4.2"},
      {:plug_cowboy, "~> 2.0"}
    ]
  end
end
