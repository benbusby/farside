import Config

config :farside,
  port: 4001,
  redis_conn: "redis://localhost:6379",
  update_file: ".update-results",
  service_prefix: "service-",
  fallback_suffix: "-fallback",
  previous_suffix: "-previous",
  services_json: "services.json",
  index: "index.eex",
  headers: [
    {"User-Agent", "Mozilla/5.0 (Linux x86_64; rv:94.0) Gecko/20100101 Firefox/94.0"},
    {"Accept", "text/html"},
    {"Accept-Language", "en-US,en;q=0.5"},
    {"Accept-Encoding", "gzip, deflate, br"}
  ],
  queries: [
    "weather",
    "time"
  ]
