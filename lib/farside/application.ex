defmodule Farside.Application do
  @farside_port Application.fetch_env!(:farside, :port)
  @redis_conn Application.fetch_env!(:farside, :redis_conn)
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    plug_children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Farside.Router,
        options: [
          port: @farside_port
        ]
      ),
      {PlugAttack.Storage.Ets, name: Farside.Throttle.Storage, clean_period: 60_000}
    ]

    children = [
      {Redix, {@redis_conn, [name: :redix]}} |
      System.get_env("FARSIDE_NO_ROUTER") && [] || plug_children
    ]

    opts = [strategy: :one_for_one, name: Farside.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
