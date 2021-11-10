defmodule FarsideTest do
  @services_json Application.fetch_env!(:farside, :services_json)

  use ExUnit.Case
  use Plug.Test

  alias Farside.Router

  @opts Router.init([])

  test "/" do
    conn =
      :get
      |> conn("/", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "/ping" do
    conn =
      :get
      |> conn("/ping", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "PONG"
  end

  test "/:service" do
    {:ok, file} = File.read(@services_json)
    {:ok, service_list} = Poison.decode(file, as: [%{}])

    service_names =
      Enum.map(
        service_list,
        fn service -> service["type"] end
      )

    IO.puts("")

    Enum.map(service_names, fn service_name ->
      IO.puts("/#{service_name}")

      conn =
        :get
        |> conn("/#{service_name}", "")
        |> Router.call(@opts)

      assert conn.state == :set
      assert conn.status == 302
    end)
  end
end
