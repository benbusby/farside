defmodule Farside do
  @service_prefix Application.fetch_env!(:farside, :service_prefix)
  @fallback_suffix Application.fetch_env!(:farside, :fallback_suffix)
  @previous_suffix Application.fetch_env!(:farside, :previous_suffix)

  # Define relation between available services and their parent service.
  # This enables Farside to redirect with links such as:
  # farside.link/https://www.youtube.com/watch?v=dQw4w9WgXcQ
  @youtube_regex ~r/youtu(.be|be.com)|invidious|piped/
  @reddit_regex ~r/reddit.com|libreddit|redlib/
  @instagram_regex ~r/instagram.com|bibliogram/
  @twitter_regex ~r/twitter.com|nitter/
  @wikipedia_regex ~r/wikipedia.org|wikiless/
  @medium_regex ~r/medium.com|scribe/
  @odysee_regex ~r/odysee.com|librarian/
  @imgur_regex ~r/imgur.com|rimgo/
  @gtranslate_regex ~r/translate.google.com|lingva/
  @tiktok_regex ~r/tiktok.com|proxitok/
  @imdb_regex ~r/imdb.com|libremdb/
  @quora_regex ~r/quora.com|quetre/
  @gsearch_regex ~r/google.com\/search|whoogle/

  @parent_services %{
    @youtube_regex => ["invidious", "piped"],
    @reddit_regex => ["libreddit", "redlib"],
    @instagram_regex => ["bibliogram"],
    @twitter_regex => ["nitter"],
    @wikipedia_regex => ["wikiless"],
    @medium_regex => ["scribe"],
    @odysee_regex => ["librarian"],
    @imgur_regex => ["rimgo"],
    @gtranslate_regex => ["lingva"],
    @tiktok_regex => ["proxitok"],
    @imdb_regex => ["libremdb"],
    @quora_regex => ["quetre"],
    @gsearch_regex => ["whoogle"]
  }

  def get_services_map do
    service_list = CubDB.select(CubDB)
                   |> Stream.map(fn {key, _value} -> key end)
                   |> Stream.filter(fn key -> String.starts_with?(key, @service_prefix) end)
                   |> Enum.to_list

    # Match service name to list of available instances
    Enum.reduce(service_list, %{}, fn service, acc ->
      instance_list = CubDB.get(CubDB, service)

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
    # Check if service has an entry in the db, otherwise try to
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
    instances = CubDB.get(CubDB, "#{@service_prefix}#{service}")

    instances != nil && Enum.count(instances) > 0
  end

  def last_instance(service) do
    # Fetches the last selected instance for a particular service
    CubDB.get(CubDB, "#{service}#{@previous_suffix}")
  end

  def pick_instance(service) do
    instances = CubDB.get(CubDB, "#{@service_prefix}#{service}")

    # Either pick a random available instance,
    # or fall back to the default one
    instance =
      if instances != nil && Enum.count(instances) > 0 do
        if Enum.count(instances) == 1 do
          # If there's only one instance, just return that one...
          List.first(instances)
        else
          # ...otherwise pick a random one from the list, ensuring
          # that the same instance is never picked twice in a row.
          instance =
            Enum.filter(instances, &(&1 != last_instance(service)))
            |> Enum.random()

          CubDB.put(CubDB, "#{service}#{@previous_suffix}", instance)

          instance
        end
      else
        CubDB.get(CubDB, "#{service}#{@fallback_suffix}")
      end
    instance
  end

  def amend_instance(instance, service, path) do
    cond do
      String.match?(service, @instagram_regex) ->
        # Bibliogram doesn't have a 1:1 matching to Instagram URLs for users,
        # so a "/u" is appended if the requested path doesn't explicitly include
        # "/p" for a post or an empty path for the home page.
        if String.length(path) > 0 and
           !String.starts_with?(path, "p/") and
           !String.starts_with?(path, "u/") do
          "#{instance}/u"
        else
          instance
        end
      true ->
        instance
    end
  end

  def get_last_updated do
    CubDB.get(CubDB, "last_updated")
  end
end
