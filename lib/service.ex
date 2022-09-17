defmodule Service do
  @moduledoc nil
  @derive Jason.Encoder
  defstruct type: nil,
            test_url: nil,
            fallback: nil,
            instances: []
end
