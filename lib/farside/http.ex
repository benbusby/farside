defmodule Farside.Http do
  require Logger

  @headers Application.fetch_env!(:farside, :headers)
  @queries Application.fetch_env!(:farside, :queries)

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
            Logger.info("Response: [#{n}]")
            :good

          n ->
            Logger.error("Response: [#{n}]")
            :bad
        end
    end
  end

  def request(url, type) do
    cond do
      System.get_env("FARSIDE_TEST") ->
        :good

      true ->
        HTTPoison.get(url, @headers)
        |> then(&elem(&1, 1))
        |> Map.get(:status_code)
        |> case do
          n when n < 400 ->
            Logger.info("Type: #{type}, Response: [#{n}], Url: #{url}")
            :good

          n ->
            Logger.error("Type: #{type}, Response: [#{n}], Url: #{url}")
            :bad
        end
    end
  end

  def fetch_instances(service) do
    instances =
      Enum.map(service.instances, fn instance ->
        test_url =
          instance <>
            EEx.eval_string(
              service.test_url,
              query: Enum.random(@queries)
            )

        Task.async(fn ->
          reply = request(test_url, service.type)
          {test_url, reply, instance}
        end)
      end)
      |> Task.yield_many(5000)
      |> Enum.map(fn {task, res} ->
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

    %{service | instances: instances}
  end
end
