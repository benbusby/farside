import Config 

config :privacy_revolver,
  redis_conn: "redis://localhost:6379",
  fallback_str: "-fallback",
  update_file: ".update-results",
  services_json: "services.json"
