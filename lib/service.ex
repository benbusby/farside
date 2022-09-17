defmodule Service do
  @moduledoc nil

  defstruct type: nil,
            test_url: nil,
            fallback: nil,
            instances: []
end
