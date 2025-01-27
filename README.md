<div align="center" style="margin-bottom: 10px;">
<img src="https://benbusby.com/assets/images/farside.svg" alt="Farside">
</div>
<br>

<div align="center">

[![Latest Release](https://img.shields.io/github/v/release/benbusby/farside?label=Release)](https://github.com/benbusby/farside/releases)
[![MIT License](https://img.shields.io/github/license/benbusby/earthbound-themes.svg)](http://opensource.org/licenses/MIT)
[![Tests](https://github.com/benbusby/farside/actions/workflows/tests.yml/badge.svg)](https://github.com/benbusby/farside/actions/workflows/tests.yml)

<table>
  <tr>
    <td><a href="https://sr.ht/~benbusby/farside">SourceHut</a></td>
    <td><a href="https://github.com/benbusby/farside">GitHub</a></td>
  </tr>
</table>

</div>

Contents
1. [About](#about)
2. [Demo](#demo)
3. [How It Works](#how-it-works)
4. [Cloudflare](#regarding-cloudflare)
5. [Development](#development)
    1. [Environment Variables](#environment-variables)

## About

A redirecting service for FOSS alternative frontends.

[Farside](https://farside.link) provides links that automatically redirect to
working instances of privacy-oriented alternative frontends, such as Nitter,
Libreddit, etc. This allows for users to have more reliable access to the
available public instances for a particular service, while also helping to
distribute traffic more evenly across all instances and avoid performance
bottlenecks and rate-limiting.

Farside also integrates smoothly with basic redirector extensions in most
browsers. For a simple example setup,
[refer to the wiki](https://github.com/benbusby/farside/wiki/Browser-Extension).

## Demo

Farside's links work with the following structure: `farside.link/<service>/<path>`

For example:

<table>
    <tr>
        <td>Service</td>
        <td>Page</td>
        <td>Farside Link</td>
    </tr>
    <tr>
        <td><a href="https://sr.ht/~edwardloveall/Scribe/">Scribe</a></td>
        <td>View Medium post</td>
        <td><a href="https://farside.link/scribe/@ftrain/big-data-small-effort-b62607a43a8c">https://farside.link/scribe/@ftrain/big-data-small-effort-b62607a43a8c</a></td>
    </tr>
    <tr>
        <td><a href="https://github.com/spikecodes/libreddit">Libreddit</a></td>
        <td>/r/popular</td>
        <td><a href="https://farside.link/libreddit/r/popular">https://farside.link/libreddit/r/popular</a></td>
    </tr>
    <tr>
        <td><a href="https://gitdab.com/cadence/breezewiki">BreezeWiki</a></td>
        <td>Balatro Wiki</td>
        <td><a href="https://farside.link/breezewiki/balatrogame">https://farside.link/https://balatrogame.fandom.com</a></td>
    </tr>
    <tr>
        <td><a href="https://github.com/searxng/searxng">SearXNG</a></td>
        <td>Search "EFF"</td>
        <td><a href="https://farside.link/searxng/search?q=EFF">https://farside.link/searxng/search?q=EFF</a></td>
    </tr>
    <tr>
        <td><a href="https://codeberg.org/ManeraKai/simplytranslate">SimplyTranslate</a></td>
        <td>Translate "hola"</td>
        <td><a href="https://farside.link/simplytranslate/?engine=google&text=hola">https://farside.link/simplytranslate/?engine=google&text=hola</a></td>
    </tr>
    <tr>
        <td><a href="https://github.com/TheDavidDelta/lingva-translate">Lingva</a></td>
        <td>Translate "bonjour"</td>
        <td><a href="https://farside.link/lingva/auto/en/bonjour">https://farside.link/lingva/auto/en/bonjour</a></td>
    </tr>
    <tr>
        <td><a href="https://codeberg.org/video-prize-ranch/rimgo">Rimgo</a></td>
        <td>View photo album</td>
        <td><a href="https://farside.link/rimgo/a/H8M4rcp">https://farside.link/rimgo/a/H8M4rcp</a></td>
    </tr>
</table>

<sup>Note: This table doesn't include all available services. For a complete list of supported frontends, see: https://farside.link</sup>

Farside also accepts URLs to "parent" services, and will redirect to an appropriate front end service, for example:

- https://farside.link/https://balatrogame.fandom.com/wiki/Abandoned_Deck will redirect to a [BreezeWiki](https://gitdab.com/cadence/breezewiki) instance
- https://farside.link/reddit.com/r/popular will redirect to a [Libreddit](https://github.com/spikecodes/libreddit) or [Teddit](https://codeberg.org/teddit/teddit) instance
- etc.

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
- `/:service/*glob`
  - The main endpoint for redirecting a user to a working instance of a
    particular service with the specified path
  - Ex: `/libreddit/r/popular` would navigate to `<libreddit instance
    URL>/r/popular`
    - If the service provided is actually a URL to a "parent" service
      (i.e. "youtube.com" instead of "piped" or "invidious"), Farside
      will determine the correct frontend to use for the specified URL.
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
the list of working instances from the db and returns a random one from the list
and adds that instance as a new entry in the db to remove from subsequent
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

## Regarding Cloudflare
Instances for each supported service that are deployed behind Cloudflare are
not included when using [farside.link](https://farside.link). If you would like
to also access instances that use Cloudflare (in addition to instances that do
not), you can either use [cf.farside.link](https://cf.farside.link) instead, or
deploy your own instance of Farside and set
`FARSIDE_SERVICES_JSON=services-full.json` when running.

If you do decide to use [cf.farside.link](https://cf.farside.link) or use the
full instance list provided by `services-full.json`, please be aware that
Cloudflare takes steps to block site visitors using Tor (and some VPNs), and
that their mission to centralize the entire web behind their service ultimately
goes against what Farside is trying to solve. Use at your own discretion.

## Development

- Install [Go](https://go.dev/doc/install)
- Compile with `go build`

### Environment Variables

<table>
    <tr>
        <td>Name</td>
        <td>Purpose</td>
    </tr>
    <tr>
        <td>FARSIDE_TEST</td>
        <td>If enabled, bypasses the instance availability check and adds all instances to the pool</td>
    </tr>
    <tr>
        <td>FARSIDE_PORT</td>
        <td>The port to run Farside on (default: `4001`)</td>
    </tr>
    <tr>
        <td>FARSIDE_DB_DIR</td>
        <td>The path to the directory to use for storing instance data (default: `./`)</td>
    </tr>
    <tr>
        <td>FARSIDE_CF_ENABLED</td>
        <td>Set to 1 to enable redirecting to instances behind cloudflare</td>
    </tr>
    <tr>
        <td>FARSIDE_CRON</td>
        <td>Set to 0 to deactivate the periodic instance availability check</td>
    </tr>
</table>

