defmodule Instance do
  defstruct [
    instance_type: nil,
    instance_list: []
  ]
end

defmodule Instances do
  def update(filename) do
    {:ok, file} = File.read(filename)
    {:ok, json} = Poison.decode(file, as: [%Instance{}])
    for x <- json do
      IO.puts(x.instance_type)
      for y <- x.instance_list do
        IO.puts(" - " <> y)
      end
    end
  end
end

Instances.update("instances.json")
