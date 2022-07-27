import Config

config :farside,
  port: System.get_env("FARSIDE_PORT", "4001"),
  redis_conn: "redis://localhost:#{System.get_env("FARSIDE_REDIS_PORT", "6379")}",
  services_json: System.get_env("FARSIDE_SERVICES_JSON", "services.json")
