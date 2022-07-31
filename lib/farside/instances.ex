defmodule Farside.Instances do
  alias Farside.LastUpdated

  def sync(data \\ []) do
    update_file = Application.fetch_env!(:farside, :update_file)
    update_json = update_file <> ".json"

    if System.get_env("MIX_ENV") == "dev" do
      File.rename(update_json, "#{update_file}-#{to_string(DateTime.utc_now()) <> ".json"}")

      File.write(update_json, "")
    end

    LastUpdated.value(DateTime.utc_now())
    Farside.Instance.Supervisor.update_children()
  end
end
