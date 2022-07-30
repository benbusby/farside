defmodule Farside.Application do
  # @farside_port Application.fetch_env!(:farside, :port)
  # @redis_conn Application.fetch_env!(:farside, :redis_conn)
  @moduledoc false

  use Application

  require Logger

  alias Farside.LastUpdated
  alias Farside.Sync

  @impl true
  def start(_type, _args) do
    port = Application.fetch_env!(:farside, :port)

    Logger.info("Running on http://localhost:#{port}")

    maybe_loaded_children =
      case is_nil(System.get_env("FARSIDE_TEST")) do
        true ->
          [{Sync, []}]

        false ->
          Logger.info("Skipping sync job setup...")
          []
      end

    children =
      [
        Plug.Cowboy.child_spec(
          scheme: :http,
          plug: Farside.Router,
          options: [
            port: String.to_integer(port)
          ]
        ),
        {LastUpdated, DateTime.utc_now()},
        {PlugAttack.Storage.Ets, name: Farside.Throttle.Storage, clean_period: 60_000},
        {DynamicSupervisor, strategy: :one_for_one, name: :server_supervisor},
        {Registry, keys: :unique, name: :servers}
      ] ++ maybe_loaded_children

    opts = [strategy: :one_for_one, name: Farside.Supervisor]

    Supervisor.start_link(children, opts)
    |> load()
  end

  def load(response) do
    services_json = Application.fetch_env!(:farside, :services_json)
    queries = Application.fetch_env!(:farside, :queries)

    {:ok, file} = File.read(services_json)
    {:ok, json} = Jason.decode(file)

    for service_json <- json do
      service_atom =
        for {key, val} <- service_json, into: %{} do
          {String.to_existing_atom(key), val}
        end

      service = struct(%Service{}, service_atom)

      test_urls =
        Enum.map(service.instances, fn x ->
          test_url =
            x <>
              EEx.eval_string(
                service.test_url,
                query: Enum.random(queries)
              )

          {test_url, x}
        end)

      tasks =
        for {test_url, instance} <- test_urls do
          Task.async(fn ->
            reply = Farside.Http.request(test_url, service.type)
            {test_url, reply, instance}
          end)
        end

      tasks_with_results = Task.yield_many(tasks, 5000)

      instances =
        Enum.map(tasks_with_results, fn {task, res} ->
          # Shut down the tasks that did not reply nor exit
          res || Task.shutdown(task, :brutal_kill)
        end)
        |> Enum.reject(fn x -> x == nil end)
        |> Enum.filter(fn {_, data} ->
          {_test_url, value, _instance} = data
          value == :good
        end)
        |> Enum.map(fn {_, data} ->
          {_test_url, _value, instance} = data
          instance
        end)

      service = %{service | instances: instances}

      Farside.Instance.Supervisor.start(service)
    end

    LastUpdated.value(DateTime.utc_now())

    response
  end
end
