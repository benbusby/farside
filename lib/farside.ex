defmodule Farside do
  @service_prefix Application.fetch_env!(:farside, :service_prefix)
  @fallback_suffix Application.fetch_env!(:farside, :fallback_suffix)
  @previous_suffix Application.fetch_env!(:farside, :previous_suffix)

  # Define relation between available services and their parent service.
  # This enables Farside to redirect with links such as:
  # farside.link/https://www.youtube.com/watch?v=dQw4w9WgXcQ
  @parent_services %{
    ~r/youtu(.be|be.com)/ => ["invidious", "piped"],
    ~r/reddit.com/ => ["libreddit", "teddit"],
    ~r/instagram.com/ => ["bibliogram"],
    ~r/twitter.com/ => ["nitter"],
    ~r/wikipedia.org/ => ["wikiless"],
    ~r/medium.com/ => ["scribe"],
    ~r/odysee.com/ => ["librarian"],
    ~r/imgur.com/ => ["rimgo"],
    ~r/translate.google.com/ => ["lingva"]
  }

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

  def get_service(service) do
    # Check if service has an entry in Redis, otherwise try to
    # match against available parent services
    service_name = cond do
      !check_service(service) ->
        Enum.find_value(
          @parent_services,
          fn {k, v} ->
            String.match?(service, k) && Enum.random(v)
          end)
      true ->
        service
    end

    service_name
  end

  def check_service(service) do
    # Checks to see if a specific service has instances available
    # in redis
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

    Enum.count(instances) > 0
  end

  def last_instance(service) do
    # Fetches the last selected instance for a particular service
    {:ok, previous} =
      Redix.command(
        :redix,
        ["GET", "#{service}#{@previous_suffix}"]
      )
    previous
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
        if Enum.count(instances) == 1 do
          # If there's only one instance, just return that one...
          List.first(instances)
        else
          # ...otherwise pick a random one from the list, ensuring
          # that the same instance is never picked twice in a row.
          instance =
            Enum.filter(instances, &(&1 != last_instance(service)))
            |> Enum.random()

          Redix.command(
            :redix,
            ["SET", "#{service}#{@previous_suffix}", instance]
          )

          instance
        end
      else
        {:ok, result} =
          Redix.command(
            :redix,
            ["GET", "#{service}#{@fallback_suffix}"]
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
