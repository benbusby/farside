defmodule Farside.Router do
  @index Application.fetch_env!(:farside, :index)

  use Plug.Router

  plug(Farside.Throttle)
  plug(:match)
  plug(:dispatch)

  get "/" do
    resp =
      EEx.eval_file(
        @index,
        last_updated: Farside.get_last_updated(),
        services: Farside.get_services_map()
      )

    send_resp(conn, 200, resp)
  end

  get "/ping" do
    # Useful for app healthcheck
    {:ok, resp} = Redix.command(:redix, ["PING"])
    send_resp(conn, 200, resp)
  end

  get "/:service/*glob" do
    path = Enum.join(glob, "/")
    instance = Farside.pick_instance(service)

    # Redirect to the available instance
    conn
    |> Plug.Conn.resp(:found, "")
    |> Plug.Conn.put_resp_header(
      "location",
      "#{instance}/#{path}"
    )
  end
end
