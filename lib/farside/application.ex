defmodule Farside.Application do
  #@farside_port Application.fetch_env!(:farside, :port)
  #@redis_conn Application.fetch_env!(:farside, :redis_conn)
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    redis_conn = Application.fetch_env!(:farside, :redis_conn)
    farside_port = Application.fetch_env!(:farside, :port)
    IO.puts "Runing on http://localhost:#{farside_port}"
    IO.puts "Redis conn: #{redis_conn}"

    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Farside.Router,
        options: [
          port: String.to_integer(farside_port)
        ]
      ),
      {PlugAttack.Storage.Ets, name: Farside.Throttle.Storage, clean_period: 60_000},
      {Redix, {redis_conn, [name: :redix]}},
      Farside.Scheduler,
      Farside.Server
    ]

    opts = [strategy: :one_for_one, name: Farside.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
