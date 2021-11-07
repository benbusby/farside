defmodule Farside.Application do
  @redis_conn Application.fetch_env!(:farside, :redis_conn)
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(scheme: :http, plug: Farside.Router, options: [port: 4001]),
      {Redix, {@redis_conn, [name: :redix]}}
    ]

    opts = [strategy: :one_for_one, name: Farside.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
