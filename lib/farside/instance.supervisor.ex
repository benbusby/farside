defmodule Farside.Instance.Supervisor do
  use DynamicSupervisor

  alias __MODULE__, as: SUPERVISOR
  alias Farside.Instance, as: SERVER

  @name :server_supervisor
  @registry_name :servers

  def child_spec() do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: @name)
  end

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: @name)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start(opts \\ %{}) do
    child_spec = {SERVER, opts}

    DynamicSupervisor.start_child(@name, child_spec)
  end

  def stop(id) do
    case Registry.lookup(@registry_name, id) do
      [] ->
        :ok

      [{pid, _}] ->
        Process.exit(pid, :shutdown)
        :ok
    end
  end

  def update_children() do
    list()
    |> Enum.each(fn x ->
      SERVER.via_tuple(x)
      |> GenServer.cast(:update)
    end)
  end

  def whereis(id) do
    case Registry.lookup(@registry_name, id) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  def find_or_create(id) do
    if process_exists?(id) do
      {:ok, id}
    else
      id |> start
    end
  end

  def exists?(id) do
    case Registry.lookup(@registry_name, id) do
      [] -> false
      _ -> true
    end
  end

  def list do
    DynamicSupervisor.which_children(@name)
    |> Enum.map(fn {_, account_proc_pid, _, _} ->
      Registry.keys(@registry_name, account_proc_pid)
      |> List.first()
    end)
    |> Enum.sort()
  end

  def process_exists?(hash) do
    case Registry.lookup(@registry_name, hash) do
      [] -> false
      _ -> true
    end
  end
end
