import Config

config :farside,
  update_file: ".update-results",
  service_prefix: "service-",
  index: "index.eex",
  route: "route.eex",
  headers: [
    {"User-Agent", "Mozilla/5.0 (compatible; Farside/0.1.0; +https://farside.link)"},
    {"Accept", "text/html"},
    {"Accept-Language", "en-US,en;q=0.5"},
    {"Accept-Encoding", "gzip, deflate, br"}
  ],
  queries: [
    "weather",
    "time"
  ],
  recv_timeout: System.get_env("FARSIDE_TIMEOUT") || "8000"
