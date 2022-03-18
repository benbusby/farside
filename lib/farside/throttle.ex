defmodule Farside.Throttle do
  import Plug.Conn
  use PlugAttack

  rule "throttle per ip", conn do
    # throttle to 1 request per second
    throttle(conn.remote_ip,
      period: 1_000,
      limit: 1,
      storage: {PlugAttack.Storage.Ets, Farside.Throttle.Storage}
    )
  end

  def allow_action(conn, _data, _opts), do: conn

  def block_action(conn, _data, _opts) do
    conn = assign(conn, :throttle, 1)
    conn
  end
end
