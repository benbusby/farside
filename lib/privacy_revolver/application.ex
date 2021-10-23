defmodule PrivacyRevolver.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(scheme: :http, plug: PrivacyRevolver.Router, options: [port: 4001]),
      {Redix, {"redis://localhost:6379", [name: :redix]}}
    ]

    opts = [strategy: :one_for_one, name: PrivacyRevolver.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
