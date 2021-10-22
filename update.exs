defmodule Instance do
  defstruct [
    instance_type: nil,
    instance_test: nil,
    instance_list: []
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
    {:ok, file} = File.read(filename)
    {:ok, json} = Poison.decode(file, as: [%Instance{}])
    for service <- json do
      result = Enum.filter(service.instance_list, fn(url) ->
        request(url <> service.instance_test) == :good
      end)
      # TODO: Output result to redis
      IO.inspect(result)
    end
  end
end

Instances.update("instances.json")
