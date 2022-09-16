defmodule Farside.Server.HealthyCheck do
  @moduledoc """
  Module to validate healthy servers
  """
  use Task

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
      90_000 ->
        run()
        poll()
    end
  end

  def load(params) do
    Registry.dispatch(:status, "healthy", fn entries ->
      for {pid, url} <- entries do
        GenServer.cast(pid, :check)
      end
    end)
    params
  end

  def run() do
    Registry.dispatch(:status, "healthy", fn entries ->
      for {pid, url} <- entries do
        GenServer.cast(pid, :check)
      end
    end)
  end
end
