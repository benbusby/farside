defmodule Farside do
  @service_prefix Application.fetch_env!(:farside, :service_prefix)
  @fallback_str Application.fetch_env!(:farside, :fallback_str)

  def get_services_map do
    {:ok, service_list} = Redix.command(:redix, ["KEYS", "#{@service_prefix}*"])

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

  def pick_instance(service) do
    {:ok, instances} =
      Redix.command(
        :redix,
        [
          "LRANGE",
          "#{@service_prefix}#{service}",
          "0",
          "-1"
        ]
      )

    # Either pick a random available instance, 
    # or fall back to the default one
    instance =
      if Enum.count(instances) > 0 do
        Enum.random(instances)
      else
        {:ok, result} =
          Redix.command(
            :redix,
            ["GET", "#{service}#{@fallback_str}"]
          )

        result
      end

    instance
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
