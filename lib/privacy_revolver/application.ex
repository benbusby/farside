defmodule PrivacyRevolver.Application do
  @redis_conn Application.fetch_env!(:privacy_revolver, :redis_conn)
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(scheme: :http, plug: PrivacyRevolver.Router, options: [port: 4001]),
      {Redix, {@redis_conn, [name: :redix]}}
    ]

    opts = [strategy: :one_for_one, name: PrivacyRevolver.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
