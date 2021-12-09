defmodule Farside.Application do
  @farside_port Application.fetch_env!(:farside, :port)
  @redis_conn Application.fetch_env!(:farside, :redis_conn)
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Farside.Router,
        options: [
          port: @farside_port
        ]
      ),
      {PlugAttack.Storage.Ets, name: Farside.Throttle.Storage, clean_period: 60_000},
      {Redix, {@redis_conn, [name: :redix]}},
      Farside.Scheduler,
      Farside.Server
    ]

    opts = [strategy: :one_for_one, name: Farside.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
