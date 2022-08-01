defmodule Farside.Instance.Check do
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
      60_000 ->
        run()
        poll()
    end
  end

  defp run() do
    Farside.Instance.Supervisor.sync_empty_instances()
  end
end
