
defmodule WASM.Compiler.Modules do
  @moduledoc false

  alias WASM.Compiler.State
  
  def execute(pid, _opts) do
    IO.inspect("Compiler modules")
    Enum.each(State.get_elixir_modules(pid), fn x ->
      IO.inspect(x, [limit: 2, label: "module"])
    end)
  end
end

