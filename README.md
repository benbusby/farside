![Farside](img/farside.png)

FOSS alternative redirecting service

[![Elixir CI](https://github.com/benbusby/privacy-revolver/actions/workflows/elixir.yml/badge.svg)](https://github.com/benbusby/privacy-revolver/actions/workflows/elixir.yml)

A tool for evenly distributing traffic across various open source alternative frontends

### Development

- Install [redis](https://redis.io)
- Install [elixir](https://elixir-lang.org/install.html)
- Start redis: `redis-server /usr/local/etc/redis.conf`
- Install dependencies: `mix deps.get`
- Initialize redis contents: `mix run update.exs`
- Run Farside: `mix run --no-halt`
  - Uses localhost:4001
