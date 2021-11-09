import Config

config :farside,
  redis_conn: "redis://localhost:6379",
  fallback_str: "-fallback",
  update_file: ".update-results",
  service_prefix: "service-",
  services_json: "services.json",
  index: "index.eex"
