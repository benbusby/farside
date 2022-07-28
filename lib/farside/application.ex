defmodule Farside.Application do
  # @farside_port Application.fetch_env!(:farside, :port)
  # @redis_conn Application.fetch_env!(:farside, :redis_conn)
  @moduledoc false

  use Application

  require Logger

  alias Farside.LastUpdated

  @impl true
  def start(_type, _args) do
    port = Application.fetch_env!(:farside, :port)

    Logger.info("Running on http://localhost:#{port}")

    sync =
      case is_nil(System.get_env("FARSIDE_TEST")) do
        true ->
          Logger.info("Skipping sync job setup...")
          []

        false ->
          {Farside.Sync, []}
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
      ] ++ sync

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

      Logger.info("Service: #{service.type}")

      instances =
        Enum.filter(service.instances, fn instance_url ->
          request_url =
            instance_url <>
              EEx.eval_string(
                service.test_url,
                query: Enum.random(queries)
              )

          Logger.info("Testing: #{request_url}")

          Farside.Http.request(request_url) == :good
        end)

      service = %{service | instances: instances}

      Farside.Server.Supervisor.start(service)
    end

    LastUpdated.value(DateTime.utc_now())

    response
  end
end
