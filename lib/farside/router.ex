defmodule Farside.Router do
  @fallback_str Application.fetch_env!(:farside, :fallback_str)

  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "")
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
        ["LRANGE", service, "0", "-1"]
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
