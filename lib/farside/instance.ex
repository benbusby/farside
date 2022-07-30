defmodule Farside.Instance do
  use GenServer

  require Logger

  alias Farside.Http

  @registry_name :servers
  @update_file Application.fetch_env!(:farside, :update_file)

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

    :ets.insert(ref, {:data, init_arg})

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

  def handle_cast(
        :update,
        state
      ) do
    service = :ets.lookup(String.to_atom(state.type), :data)

    {_, service} = List.first(service)

    service = Http.fetch_instances(service)

    :ets.delete_all_objects(String.to_atom(state.type))

    :ets.insert(state.ref, {:data, service})

    File.write(@update_file, service.fallback)

    {:noreply, state}
  end

  @doc false
  def via_tuple(data, registry \\ @registry_name) do
    {:via, Registry, {registry, data}}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    :ets.delete(names)
    {:noreply, {names, refs}}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
