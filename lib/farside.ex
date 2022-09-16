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
  @quora_regex ~r/quora.com|quetre/

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
    @quora_regex => ["quetre"]
  }

  alias Farside.LastUpdated

  def get_services_map do
    services_map =
      Farside.Instance.Supervisor.list()
      |> Enum.map(fn service ->
        data = :ets.lookup(String.to_atom(service), :default) |> List.first()

        instances =
          case is_nil(data) do
            true ->
              []

            false ->
              {_, service} = data

              registry = "#{service.type}_healthy"

              instances =
                for instance <- service.instances do
                  matches = Registry.match(:status, registry, instance)

                  {_, instance} =
                    case Enum.count(matches) > 0 do
                      true -> List.first(matches)
                      false -> {:error, nil}
                    end

                  instance
                end
                |> Enum.reject(fn x -> x == nil end)

              Map.put(
                service,
                :instances,
                instances
              )
          end
      end)
  end

  def get_service(service) do
    service_name =
      Enum.find_value(
        @parent_services,
        fn {k, v} ->
          String.match?(service, k) && Enum.random(v)
        end
      )

    data = :ets.lookup(String.to_atom(service_name), :default)

    data =
      case data do
        nil -> []
        _ -> data
      end

    case Enum.count(data) > 0 do
      true ->
        {_, service} = List.first(data)

        registry = "#{service.type}_healthy"

        instances =
          for instance <- service.instances do
            matches = Registry.match(:status, registry, instance)

            {_, instance} =
              case Enum.count(matches) > 0 do
                true -> List.first(matches)
                false -> {:error, nil}
              end

            instance
          end
          |> Enum.reject(fn x -> x == nil end)

        service = Map.put(
          service,
          :instances,
          instances
        )

        case Enum.count(service.instances) > 0 do
          true -> Enum.random(service.instances)
          false -> service.fallback
        end

      false ->
        "/"
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

  def save_results(file, data) do
    if System.get_env("MIX_ENV") == "dev" do
      {:ok, file} = File.open(file, [:append])
      bin = :erlang.term_to_binary(data)
      IO.binwrite(file, bin)
      File.close(file)
    end
  end

  def restore_term(file) do
    {:ok, bin} = File.read(file)
    :erlang.binary_to_term(bin)
  end
end
