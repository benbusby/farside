import Config

config :farside,
  port: System.get_env("FARSIDE_PORT", nil),
  services_json: System.get_env("FARSIDE_SERVICES_JSON", "services.json"),
  services_json_data: System.get_env("FARSIDE_SERVICES_JSON_DATA") || ""