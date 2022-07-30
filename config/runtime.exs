import Config

config :farside,
  port: System.get_env("FARSIDE_PORT", "4001"),
  services_json: System.get_env("FARSIDE_SERVICES_JSON", "services.json")
