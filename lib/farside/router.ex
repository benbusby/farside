defmodule Farside.Router do
  @index Application.fetch_env!(:farside, :index)
  @route Application.fetch_env!(:farside, :route)

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

  get "/_/:service/*glob" do
    r_path = String.slice(conn.request_path, 2..-1)

    resp =
      EEx.eval_file(
        @route,
        service: service,
        instance_url: r_path
      )

    send_resp(conn, 200, resp)
  end

  get "/:service/*glob" do
    path = Enum.join(glob, "/")
    instance = cond do
      conn.assigns[:throttle] != nil ->
        Farside.last_instance(service)
      true ->
        Farside.pick_instance(service)
    end
    IO.inspect(get_req_header(conn, "throttle"))
    IO.inspect(instance)

    params =
      cond do
        String.length(conn.query_string) > 0 ->
          "?#{conn.query_string}"

        true ->
          ""
      end

    # Redirect to the available instance
    conn
    |> Plug.Conn.resp(:found, "")
    |> Plug.Conn.put_resp_header(
      "location",
      "#{instance}/#{path}#{params}"
    )
  end
end
