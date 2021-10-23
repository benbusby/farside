defmodule PrivacyRevolver.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/ping" do
    send_resp(conn, 200, "pong")
  end
end
