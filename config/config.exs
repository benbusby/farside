import Config

config :farside,
  redis_conn: "redis://localhost:6379",
  update_file: ".update-results",
  service_prefix: "service-",
  fallback_suffix: "-fallback",
  previous_suffix: "-previous",
  services_json: "services.json",
  index: "index.eex"
