defmodule Service do
  defstruct [
    type: nil,
    test_url: nil,
    fallback: nil,
    instances: []
  ]
end

defmodule Instances do
  def request(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        # TODO: Add validation of results, not just status code
        :good
      _ ->
        :bad
    end
  end

  def update(filename) do
    {:ok, conn} = Redix.start_link(
      "redis://localhost:6379",
      name: :redix
    )
    {:ok, file} = File.read(filename)
    {:ok, json} = Poison.decode(file, as: [%Service{}])

    # Loop through all instances and check each for availability
    for service <- json do
      result = Enum.filter(service.instances, fn(instance_url) ->
        request(instance_url <> service.test_url) == :good
      end)

      add_to_redis(conn, service, result)
    end
  end

  def add_to_redis(conn, service, instances) do
    # Remove previous list of instances
    Redix.command(conn, [
      "DEL",
      service.type
    ])

    # Update with new list of available instances
    Redix.command(conn, [
      "LPUSH",
      service.type
    ] ++ instances)

    # Set fallback to one of the available instances,
    # or the default instance if all are "down"
    if Enum.count(instances) > 0 do
      Redix.command(conn, [
        "SET",
        service.type <> "-fallback",
        Enum.random(instances)
      ])
    else
      Redix.command(conn, [
        "SET",
        service.type <> "-fallback",
        service.fallback
      ])
    end
  end
end

Instances.update("services.json")
