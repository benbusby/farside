defmodule Farside.Instances do
  alias Farside.LastUpdated

  def sync() do
    update_file = Application.fetch_env!(:farside, :update_file)

    File.rm("#{update_file}-prev")

    File.rename(update_file, "#{update_file}-prev")

    File.write(update_file, "")

    LastUpdated.value(DateTime.utc_now())

    Farside.Instance.Supervisor.update_children()
  end
end
