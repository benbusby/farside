defmodule Farside.MixProject do
  use Mix.Project

  @source_url "https://github.com/benbusby/farside.git"
  @version "0.1.1"
  @app :farside

  def project do
    [
      app: @app,
      version: @version,
      name: "farside",
      elixir: "~> 1.8",
      source_url: @source_url,
      start_permanent: Mix.env() == :prod || Mix.env() == :cli,
      deps: deps(),
      aliases: aliases(),
      description: description(),
      package: package(),
      releases: [{@app, release()}],
      preferred_cli_env: [release: :cli]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Farside.Application, []}
    ]
  end

  defp aliases do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.8"},
      {:jason, "~> 1.1"},
      {:plug_attack, "~> 0.4.2"},
      {:plug_cowboy, "~> 2.0"},
      {:credo, "~> 1.6.3", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:bakeware, runtime: false, only: :cli}
    ]
  end

  defp description() do
    "A redirecting service for FOSS alternative frontends."
  end

  defp package() do
    [
      name: "farside",
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Ben Busby, Jason Clark"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/benbusby/farside"}
    ]
  end

  defp release do
    [
      overwrite: true,
      cookie: "#{@app}_cookie",
      quiet: true,
      steps: [:assemble, &Bakeware.assemble/1],
      strip_beams: Mix.env() == :cli
    ]
  end
end
