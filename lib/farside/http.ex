defmodule Farside.Http do
  require Logger

  @headers Application.fetch_env!(:farside, :headers)
  @queries Application.fetch_env!(:farside, :queries)
  @recv_timeout String.to_integer(Application.fetch_env!(:farside, :recv_timeout))

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
        HTTPoison.get(url, @headers, timeout: 5000, recv_timeout: @recv_timeout)
        |> then(&elem(&1, 1))
        |> Map.get(:status_code)
        |> case do
          n when n < 400 ->
            Logger.info("Type: #{type}, Response: [#{n}], Url: #{url}")
            :good

          nil ->
            Logger.error("Type: #{type}, Response: [408], Url: #{url}")
            :bad

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
      |> Task.yield_many(@recv_timeout)
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

  def test_service(service) do
    url = service.url <> service.test_url

    test_url =
      EEx.eval_string(
        url,
        query: Enum.random(@queries)
      )

    task =
      Task.async(fn ->
        reply = request(test_url, service.type)
        {test_url, reply, service}
      end)

    data =
      case Task.yield(task, @recv_timeout) || Task.shutdown(task) do
        {:ok, result} ->
          result

        nil ->
          nil
      end

    unless is_nil(data) do
      {_test_url, value, _service} = data
      value
    else
      :bad
    end
  end
end
