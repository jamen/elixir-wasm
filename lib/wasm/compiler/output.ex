
defmodule WASM.Compiler.Output do
  @moduledoc false

  alias WASM.Compiler.State
  
  def execute(pid, _opts) do
    IO.inspect("Compiler output")
    IO.inspect(State.get_wasm_modules(pid))
  end
end

