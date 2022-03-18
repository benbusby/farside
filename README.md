![Farside](img/farside.svg)

[![Latest Release](https://img.shields.io/github/v/release/benbusby/farside?label=Release)](https://github.com/benbusby/farside/releases)
[![MIT License](https://img.shields.io/github/license/benbusby/earthbound-themes.svg)](http://opensource.org/licenses/MIT)
[![Elixir CI](https://github.com/benbusby/privacy-revolver/actions/workflows/elixir.yml/badge.svg)](https://github.com/benbusby/privacy-revolver/actions/workflows/elixir.yml)

A redirecting service for FOSS alternative frontends.

[Farside](https://farside.link) provides links that automatically redirect to
working instances of privacy-oriented alternative frontends, such as Nitter,
Libreddit, etc. This allows for users to have more reliable access to the
available public instances for a particular service, while also helping to
distribute traffic more evenly across all instances and avoid performance
bottlenecks and rate-limiting.

## Demo

Farside's links work with the following structure: `farside.link/<service>/<path>`

For example:

| Service | Page | Farside Link |
| -- | -- | -- |
| [Libreddit](https://github.com/spikecodes/libreddit) | /r/popular | https://farside.link/libreddit/r/popular
| [Teddit](https://codeberg.org/teddit/teddit) | /r/popular | https://farside.link/teddit/r/popular
| [Nitter](https://github.com/zedeus/nitter) | User Profile | https://farside.link/nitter/josevalim
| [Invidious](https://github.com/iv-org/invidious) | Home Page | https://farside.link/invidious
| [Piped](https://github.com/TeamPiped/Piped) | Video Page | https://farside.link/piped/watch?v=eBGIQ7ZuuiU
| [Bibliogram](https://sr.ht/~cadence/bibliogram/) | User Profile | https://farside.link/bibliogram/u/kbdfans
| [Whoogle](https://github.com/benbusby/whoogle-search) | Search "Elixir" | https://farside.link/whoogle/search?q=elixir&lang_interface=en
| [SearX](https://github.com/searx/searx) | Search "Redis" | https://farside.link/searx/search?q=redis
| [SearXNG](https://github.com/searxng/searxng) | Search "EFF" | https://farside.link/searxng/search?q=EFF
| [SimplyTranslate](https://git.sr.ht/~metalune/simplytranslate_web) | Translate "hola" | https://farside.link/simplytranslate/?engine=google&text=hola
| [Lingva](https://github.com/TheDavidDelta/lingva-translate) | Translate "bonjour" | https://farside.link/lingva/auto/en/bonjour
| [Rimgo](https://codeberg.org/video-prize-ranch/rimgo) | View photo album | https://farside.link/rimgo/a/H8M4rcp
| [Scribe](https://sr.ht/~edwardloveall/scribe/) | View Medium post | https://farside.link/scribe/@ftrain/big-data-small-effort-b62607a43a8c

## How It Works

The app runs with an internally scheduled cron task that queries all instances
for services defined in [services.json](services.json) every 5 minutes. For
each instance, as long as the instance takes <5 seconds to respond and returns
a successful response code, the instance is added to a list of available
instances for that particular service. If not, it is discarded until the next
update period.

Farside's routing is very minimal, with only the following routes:

- `/`
  - The app home page, displaying all live instances for every service
- `/ping`
  - A passthrough "ping" to redis to ensure both app and redis are working
- `/:service/*glob`
  - The main endpoint for redirecting a user to a working instance of a
    particular service with the specified path
  - Ex: `/libreddit/r/popular` would navigate to `<libreddit instance
    URL>/r/popular`
  - Note that a path is not required. `/libreddit` for example will still
    redirect the user to a working libreddit instance
- `/_/:service/*glob`
  - Achieves the same redirect as the main `/:service/*glob` endpoint, but
    preserves a short landing page in the browser's history to allow quickly
    jumping between instances by navigating back.
  - Ex: `/_/nitter` -> nitter instance A -> (navigate back one page) -> nitter
    instance B -> ...
  - *Note: Uses Javascript to preserve the page in history*

When a service is requested with the `/:service/...` endpoint, Farside requests
the list of working instances from Redis and returns a random one from the list
and adds that instance as a new entry in Redis to remove from subsequent
requests for that service. For example:

A user navigates to `/nitter` and is redirected to `nitter.net`. The next user
to request `/nitter` will be guaranteed to not be directed to `nitter.net`, and
will instead be redirected to a separate (random) working instance. That
instance will now take the place of `nitter.net` as the "reserved" instance, and
`nitter.net` will be returned to the list of available Nitter instances.

This "reserving" of previously chosen instances is performed in an attempt to
ensure better distribution of traffic to available instances for each service.

Farside also has built-in IP ratelimiting for all requests, enforcing only one
request per second per IP.

## Development

- Install [redis](https://redis.io)
- Install [elixir](https://elixir-lang.org/install.html)
- Start redis: `redis-server`
- Install dependencies: `mix deps.get`
- Initialize redis contents: `mix run -e Farside.Instances.sync`
- Run Farside: `mix run --no-halt`
  - Uses localhost:4001

### Environment Variables

| Name | Purpose |
| -- | -- |
| FARSIDE_TEST | If enabled, bypasses the instance availability check and adds all instances to the pool. |
