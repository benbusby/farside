defmodule Farside.Instances do
  @fallback_suffix Application.fetch_env!(:farside, :fallback_suffix)
  @update_file Application.fetch_env!(:farside, :update_file)
  @service_prefix Application.fetch_env!(:farside, :service_prefix)
  @headers Application.fetch_env!(:farside, :headers)
  @queries Application.fetch_env!(:farside, :queries)
  @debug_header "======== "
  @debug_spacer "         "

  # SearXNG instance uptimes are inspected as part of the nightly Farside build,
  # and should not be included in the constant periodic update.
  @skip_service_updates ["searxng"]

  def sync() do
    File.rename(@update_file, "#{@update_file}-prev")
    update()

    # Add UTC time of last update
    CubDB.put(CubDB, "last_updated", Calendar.strftime(DateTime.utc_now(), "%c"))
  end

  def request(url) do
    cond do
      System.get_env("FARSIDE_TEST") ->
        :good

      true ->
        HTTPoison.get(url, @headers)
        |> then(&elem(&1, 1))
        |> Map.get(:status_code)
        |> case do
          n when n < 400 ->
            IO.puts("#{@debug_spacer}✓ [#{n}]")
            :good

          n ->
            IO.puts("#{@debug_spacer}x [#{(n && n) || "error"}]")
            :bad
        end
    end
  end

  def update() do
    services_json = Application.fetch_env!(:farside, :services_json)
    {:ok, file} = File.read(services_json)
    {:ok, json} = Jason.decode(file)

    # Loop through all instances and check each for availability
    for service_json <- json do
      service_atom = for {key, val} <- service_json, into: %{} do
        {String.to_existing_atom(key), val}
      end

      service = struct(%Service{}, service_atom)

      IO.puts("#{@debug_header}#{service.type}")

      result = cond do
        Enum.member?(@skip_service_updates, service.type) ->
          service.instances
        true ->
          Enum.filter(service.instances, fn instance_url ->
            request_url =
              instance_url <>
                EEx.eval_string(
                  service.test_url,
                  query: Enum.random(@queries)
                )

            IO.puts("#{@debug_spacer}#{request_url}")

            request(request_url) == :good
          end)
      end

      add_to_db(service, result)
      log_results(service.type, result)
    end
  end

  def add_to_db(service, instances) do
    # Remove previous list of instances
    CubDB.delete(CubDB, "#{@service_prefix}#{service.type}")

    # Update with new list of available instances
    CubDB.put(CubDB, "#{@service_prefix}#{service.type}", instances)

    # Set fallback to one of the available instances,
    # or the default instance if all are "down"
    if Enum.count(instances) > 0 do
      CubDB.put(CubDB, "#{service.type}#{@fallback_suffix}", Enum.random(instances))
    else
      CubDB.put(CubDB, "#{service.type}#{@fallback_suffix}", service.fallback)
    end
  end

  def log_results(service_name, results) do
    {:ok, file} = File.open(@update_file, [:append, {:delayed_write, 100, 20}])
    IO.write(file, "#{service_name}: #{inspect(results)}\n")
    File.close(file)
  end
end
