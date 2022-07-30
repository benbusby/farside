defmodule Farside do
  @service_prefix Application.fetch_env!(:farside, :service_prefix)

  # Define relation between available services and their parent service.
  # This enables Farside to redirect with links such as:
  # farside.link/https://www.youtube.com/watch?v=dQw4w9WgXcQ
  @youtube_regex ~r/youtu(.be|be.com)|invidious|piped/
  @reddit_regex ~r/reddit.com|libreddit|teddit/
  @instagram_regex ~r/instagram.com|bibliogram/
  @twitter_regex ~r/twitter.com|nitter/
  @wikipedia_regex ~r/wikipedia.org|wikiless/
  @medium_regex ~r/medium.com|scribe/
  @odysee_regex ~r/odysee.com|librarian/
  @imgur_regex ~r/imgur.com|rimgo/
  @gtranslate_regex ~r/translate.google.com|lingva/
  @tiktok_regex ~r/tiktok.com|proxitok/
  @imdb_regex ~r/imdb.com|libremdb/
  @quora_regex ~r/quora.com|querte/

  @parent_services %{
    @youtube_regex => ["invidious", "piped"],
    @reddit_regex => ["libreddit", "teddit"],
    @instagram_regex => ["bibliogram"],
    @twitter_regex => ["nitter"],
    @wikipedia_regex => ["wikiless"],
    @medium_regex => ["scribe"],
    @odysee_regex => ["librarian"],
    @imgur_regex => ["rimgo"],
    @gtranslate_regex => ["lingva"],
    @tiktok_regex => ["proxitok"],
    @imdb_regex => ["libremdb"],
    @quora_regex => ["querte"]
  }

  alias Farside.LastUpdated

  def get_services_map do
    Farside.Instance.Supervisor.list()
    |> Enum.reduce(%{}, fn service, acc ->
      {_, data} = :ets.lookup(String.to_atom(service), :data) |> List.first()

      Map.put(
        acc,
        String.replace_prefix(
          service,
          @service_prefix,
          ""
        ),
        data.instances
      )
    end)
  end

  def get_service(service \\ "libreddit/r/popular") do
    service_name =
      Enum.find_value(
        @parent_services,
        fn {k, v} ->
          String.match?(service, k) && Enum.random(v)
        end
      )

    data = :ets.lookup(String.to_atom(service_name), :data)

    {_, service} = List.first(data)

    case Enum.count(service.instances) > 0 do
      true -> Enum.random(service.instances)
      false -> service.fallback
    end
  end

  def get_last_updated do
    LastUpdated.value()
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
end
