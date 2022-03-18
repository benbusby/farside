defmodule FarsideTest do
  @services_json Application.fetch_env!(:farside, :services_json)

  use ExUnit.Case
  use Plug.Test

  alias Farside.Router

  @opts Router.init([])

  def test_conn(path) do
    :timer.sleep(1000)

    :get
    |> conn(path, "")
    |> Router.call(@opts)
  end

  test "throttle" do
    first_conn =
      :get
      |> conn("/", "")
      |> Router.call(@opts)

    first_redirect = elem(List.last(first_conn.resp_headers), 1)

    throttled_conn =
      :get
      |> conn("/", "")
      |> Router.call(@opts)

    throttled_redirect = elem(List.last(first_conn.resp_headers), 1)

    assert throttled_conn.state == :sent
    assert throttled_redirect == first_redirect
  end

  test "/" do
    conn = test_conn("/")
    assert conn.state == :sent
    assert conn.status == 200
  end

  test "/ping" do
    conn = test_conn("/ping")
    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "PONG"
  end

  test "/:service" do
    {:ok, file} = File.read(@services_json)
    {:ok, service_list} = Jason.decode(file)

    service_names =
      Enum.map(
        service_list,
        fn service -> service["type"] end
      )

    IO.puts("")

    Enum.map(service_names, fn service_name ->
      conn = test_conn("/#{service_name}")
      first_redirect = elem(List.last(conn.resp_headers), 1)

      IO.puts("    /#{service_name} (#1) -- #{first_redirect}")
      assert conn.state == :set
      assert conn.status == 302

      conn = test_conn("/#{service_name}")
      second_redirect = elem(List.last(conn.resp_headers), 1)

      IO.puts("    /#{service_name} (#2) -- #{second_redirect}")
      assert conn.state == :set
      assert conn.status == 302
      assert first_redirect != second_redirect
    end)
  end
end
