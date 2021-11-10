defmodule Service do
  defstruct type: nil,
            test_url: nil,
            fallback: nil,
            instances: []
end
