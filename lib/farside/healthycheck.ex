defmodule Farside.Server.HealthyCheck do
  @moduledoc """
  Module to validate healthy servers
  """
  use Task
  alias Farside.LastUpdated

  require Logger

  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [args]},
      type: :worker
    }
  end

  def start_link(_arg) do
    Task.start_link(&poll/0)
  end

  def poll() do
    receive do
    after
      300_000 ->
        run()
        poll()
    end
  end

  def run() do
    LastUpdated.value(DateTime.utc_now())

    Logger.info("Healthy Service Check Running")

    Registry.dispatch(:status, "healthy", fn entries ->
      for {pid, _url} <- entries do
        GenServer.cast(pid, :check)
      end
    end)
  end
end
