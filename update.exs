defmodule Instances do
  @fallback_str Application.fetch_env!(:farside, :fallback_str)
  @update_file Application.fetch_env!(:farside, :update_file)
  @services_json Application.fetch_env!(:farside, :services_json)
  @service_prefix Application.fetch_env!(:farside, :service_prefix)

  def init() do
    File.rename(@update_file, "#{@update_file}-prev")
    update
  end

  def request(url) do
    cond do
      System.get_env("FARSIDE_TEST") ->
        :good
      true ->
        case HTTPoison.get(url) do
          {:ok, %HTTPoison.Response{status_code: 200}} ->
            # TODO: Add validation of results, not just status code
            :good
          _ ->
            :bad
        end
    end
  end

  def update do
    {:ok, file} = File.read(@services_json)
    {:ok, json} = Poison.decode(file, as: [%Service{}])

    # Loop through all instances and check each for availability
    for service <- json do
      IO.puts "======== " <> service.type
      result = Enum.filter(service.instances, fn(instance_url) ->
        IO.puts "         " <> instance_url
        request(instance_url <> service.test_url) == :good
      end)

      add_to_redis(service, result)
      log_results(service.type, result)
    end
  end

  def add_to_redis(service, instances) do
    # Remove previous list of instances
    Redix.command(:redix, [
      "DEL",
      "#{@service_prefix}#{service.type}"
    ])

    # Update with new list of available instances
    Redix.command(:redix, [
      "LPUSH",
      "#{@service_prefix}#{service.type}"
    ] ++ instances)

    # Set fallback to one of the available instances,
    # or the default instance if all are "down"
    if Enum.count(instances) > 0 do
      Redix.command(:redix, [
        "SET",
        "#{service.type}#{@fallback_str}",
        Enum.random(instances)
      ])
    else
      Redix.command(:redix, [
        "SET",
        "#{service.type}#{@fallback_str}",
        service.fallback
      ])
    end
  end

  def log_results(service_name, results) do
    {:ok, file} = File.open(@update_file, [:append, {:delayed_write, 100, 20}])
    IO.write(file, "#{service_name}: #{inspect(results)}\n")
    File.close(file)
  end
end

Instances.init()

# Add UTC time of last update
Redix.command(:redix, [
  "SET",
  "last_updated",
  Calendar.strftime(DateTime.utc_now(), "%c")
])
