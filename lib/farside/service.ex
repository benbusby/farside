defmodule Farside.Service do
  use GenServer

  @moduledoc """
  Service
    this will store the service state
  """

  require Logger

  alias Farside.Http

  @registry_name :service

  defstruct url: nil,
            type: nil,
            test_url: nil,
            last_update: nil,
            status: []

  def child_spec(data) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [data]},
      type: :worker
    }
  end

  @impl true
  def init(data) do
    initial_state = %__MODULE__{
      url: data.url,
      type: data.type,
      test_url: data.test_url,
      last_update:
        DateTime.utc_now()
        |> DateTime.add(-86_400, :second),
      status: []
    }

    unhealthy = "#{data.type}_unhealthy"

    Registry.register(:status, unhealthy, data.url)
    Registry.register(:status, "unhealthy", data.url)
    {:ok, initial_state}
  end

  def start_link(data) do
    name = via_tuple(data.url)
    GenServer.start_link(__MODULE__, data, name: name)
  end

  def shutdown() do
    GenServer.call(__MODULE__, :shutdown)
  end

  @impl true
  def handle_call(
        :shutdown,
        _from,
        state
      ) do
    {:stop, {:ok, "Normal Shutdown"}, state}
  end

  @impl true
  def handle_cast(:load, state) do
    reply = Http.test_service(state)

    status = state.status ++ [reply]

    state = %{state | status: status}

    state = %{state | last_update: DateTime.utc_now()}

    {:noreply, state}
  end

  @impl true
  def handle_cast(:check, state) do
    dt =
      DateTime.utc_now()
      |> DateTime.add(-60, :second)

    state =
      case DateTime.compare(dt, state.last_update) do
        :gt ->
          reply = Http.test_service(state)

          status = state.status ++ [reply]

          max_queue = Application.get_env(:farside, :max_fail_rate, 50) + 5

          status =
            case Enum.count(status) < max_queue do
              true -> status
              false -> []
            end

          state = %{state | status: status}

          state = %{state | last_update: DateTime.utc_now()}

          healthy = "#{state.type}_healthy"
          unhealthy = "#{state.type}_unhealthy"
          dead = "#{state.type}_dead"

          Registry.unregister_match(:status, "healthy", state.url)
          Registry.unregister_match(:status, "unhealthy", state.url)
          Registry.unregister_match(:status, "dead", state.url)

          Registry.unregister_match(:status, healthy, state.url)
          Registry.unregister_match(:status, unhealthy, state.url)
          Registry.unregister_match(:status, dead, state.url)

          if reply != :good do
            filtered = Enum.reject(status, fn x -> x == :good end)

            fails_before_death = Application.get_env(:farside, :max_fail_rate, 50)

            case Enum.count(filtered) < fails_before_death do
              true ->
                Registry.register(:status, "unhealthy", state.url)
                Registry.register(:status, unhealthy, state.url)
                state

              false ->
                Registry.register(:status, "dead", state.url)
                Registry.register(:status, dead, state.url)
                %{state | status: [:bad]}
            end
          else
            Registry.register(:status, "healthy", state.url)
            Registry.register(:status, healthy, state.url)
            state
          end

        _ ->
          %{state | last_update: DateTime.utc_now()}
      end

    {:noreply, state}
  end

  @impl true
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
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, data) do
    {:noreply, data}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
