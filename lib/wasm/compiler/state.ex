
defmodule WASM.Compiler.State do
  @moduledoc false

  alias WASM.Compiler.Beam

  @initial_state %{
    elixir_modules: [],
    wasm_modules: []
  }

  def start_link() do
    Agent.start_link(fn -> @initial_state end)
  end

  # Get info from module with no hint
  def put_elixir_module(pid, module, nil) do
    {:ok, info} = Beam.debug_info(module)
    put_elixir_module(pid, module, info)
  end

  # Get info from module with BEAM code
  def put_elixir_module(pid, module, beam) when is_binary(beam) do
    {:ok, info} = Beam.debug_info(beam)
    put_elixir_module(pid, module, info)
  end

  def put_elixir_module(pid, module, info) do
    Agent.update(pid, fn state ->
      elixir_modules = Map.get(state, :elixir_modules, [])
      elixir_modules = Keyword.put(elixir_modules, module, info)
      %{ state | elixir_modules: elixir_modules }
    end)
  end

  def put_new_elixir_module(pid, module, source) do
    unless get_elixir_module(pid, module) do
      put_elixir_module(pid, module, source)
    end
  end

  def get_elixir_modules(pid) do
    Agent.get(pid, fn state -> state.elixir_modules end)
  end

  def get_elixir_module(pid, module) do
    Keyword.get(get_elixir_modules(pid), module)
  end

  def put_wasm_module(pid, module, result) do
    Agent.update(pid, fn state ->
      wasm_modules = Keyword.put(state.wasm_modules, module, result)
      %{ state | wasm_modules: wasm_modules }
    end)
  end

  def get_wasm_modules(pid) do
    Agent.get(pid, fn state -> state.wasm_modules end)
  end

  def get_wasm_module(pid, module) do
    Keyword.get(get_wasm_modules(pid), module)
  end

  defp get_info(input) do

  end
end

