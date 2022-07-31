defmodule Farside.Application do
  @moduledoc false

  use Application

  require Logger

  alias Farside.LastUpdated
  alias Farside.Sync
  alias Farside.Http

  @impl true
  def start(_type, _args) do
    port =
      case Application.fetch_env!(:farside, :port) do
        nil -> System.get_env("PORT", "4001")
        port -> port
      end

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
    services_json_data = Application.fetch_env!(:farside, :services_json_data)
    queries = Application.fetch_env!(:farside, :queries)

    reply =
      case String.length(services_json_data) < 10 do
        true ->
          file = Application.fetch_env!(:farside, :services_json)
          {:ok, data} = File.read(file)
          data

        false ->
          services_json_data
      end

    {:ok, json} = Jason.decode(reply)

    for service_json <- json do
      service_atom =
        for {key, val} <- service_json, into: %{} do
          {String.to_existing_atom(key), val}
        end

      struct(%Service{}, service_atom)
      |> Http.fetch_instances()
      |> Farside.Instance.Supervisor.start()
    end

    LastUpdated.value(DateTime.utc_now())

    response
  end
end
