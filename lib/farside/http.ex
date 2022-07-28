defmodule Farside.Http do
  require Logger

  @headers Application.fetch_env!(:farside, :headers)

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
end
