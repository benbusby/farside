defmodule Farside.Instance do
  use GenServer

  require Logger

  alias Farside.Http

  @registry_name :instance

  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [args]},
      type: :worker
    }
  end

  def init(init_arg) do
    ref =
      :ets.new(String.to_atom(init_arg.type), [
        :set,
        :named_table,
        :public,
        read_concurrency: true,
        write_concurrency: true
      ])

    :ets.insert(ref, {:default, init_arg})

    {:ok, %{type: init_arg.type, ref: ref}}
  end

  def start_link(arg) do
    name = via_tuple(arg.type)

    GenServer.start_link(__MODULE__, arg, name: name)
  end

  def shutdown() do
    GenServer.call(__MODULE__, :shutdown)
  end

  def handle_call(
        :shutdown,
        _from,
        state
      ) do
    {:stop, {:ok, "Normal Shutdown"}, state}
  end

  def handle_cast(
        :shutdown,
        state
      ) do
    {:stop, :normal, state}
  end

  @doc false
  def via_tuple(id, registry \\ @registry_name) do
    {:via, Registry, {registry, id}}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    :ets.delete(names)
    {:noreply, {names, refs}}
  end

  @impl true
  def handle_info(:load, state) do
    service = :ets.lookup(String.to_atom(state.type), :default)

    {_, service} = List.first(service)

    service.instances
    |> Enum.each(fn url ->
      initial_state = %{url: url, type: service.type, test_url: service.test_url}
      Farside.Service.Supervisor.start(initial_state)
    end)

    {:noreply, state}
  end
end
