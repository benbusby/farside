defmodule Farside.Router do
  @index Application.fetch_env!(:farside, :index)
  @fallback_str Application.fetch_env!(:farside, :fallback_str)
  @service_prefix Application.fetch_env!(:farside, :service_prefix)

  use Plug.Router

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

    {:ok, instances} =
      Redix.command(
        :redix,
        [
          "LRANGE",
          "#{@service_prefix}#{service}",
          "0",
          "-1"
        ]
      )

    # Either pick a random available instance, 
    # or fall back to the default one
    instance =
      if Enum.count(instances) > 0 do
        Enum.random(instances)
      else
        {:ok, result} =
          Redix.command(
            :redix,
            ["GET", "#{service}#{@fallback_str}"]
          )

        result
      end

    # Redirect to the available instance
    conn
    |> Plug.Conn.resp(:found, "")
    |> Plug.Conn.put_resp_header(
      "location",
      "#{instance}/#{path}"
    )
  end
end
