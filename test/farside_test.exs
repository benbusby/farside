defmodule FarsideTest do
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
end
