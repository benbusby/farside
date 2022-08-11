defmodule Farside.Instance.Sync do
  use Task

  alias Farside.Status

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
        if(Status.value() == :wait) do
          sync()
        end

        poll()
    end
  end

  defp sync() do
    Farside.Instances.sync()
  end
end
