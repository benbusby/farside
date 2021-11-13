![Farside](img/farside.svg)

___

[![Elixir CI](https://github.com/benbusby/privacy-revolver/actions/workflows/elixir.yml/badge.svg)](https://github.com/benbusby/privacy-revolver/actions/workflows/elixir.yml)

A redirecting service for FOSS alternative frontends

### Development

- Install [redis](https://redis.io)
- Install [elixir](https://elixir-lang.org/install.html)
- Start redis: `redis-server /usr/local/etc/redis.conf`
- Install dependencies: `mix deps.get`
- Initialize redis contents: `mix run update.exs`
- Run Farside: `mix run --no-halt`
  - Uses localhost:4001
