defmodule Farside do
  @service_prefix Application.fetch_env!(:farside, :service_prefix)

  def get_services_map do
    {:ok, redis_keys} = Redix.command(:redix, ["KEYS", "*"])

    # Extract only service related keys
    service_list =
      Enum.filter(
        redis_keys,
        fn key ->
          String.starts_with?(key, @service_prefix)
        end
      )

    # Match service name to list of available instances
    Enum.reduce(service_list, %{}, fn service, acc ->
      {:ok, instance_list} =
        Redix.command(
          :redix,
          ["LRANGE", service, "0", "-1"]
        )

      Map.put(
        acc,
        String.replace_prefix(
          service,
          @service_prefix,
          ""
        ),
        instance_list
      )
    end)
  end

  def get_last_updated do
    {:ok, last_updated} =
      Redix.command(
        :redix,
        ["GET", "last_updated"]
      )

    last_updated
  end
end
