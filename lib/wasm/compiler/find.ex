
defmodule WASM.Compiler.Find do
  @moduledoc """
  Take input modules and resolve the used modules.
  """

  alias WASM.Compiler.State

  def execute(pid, _opts) do
    Enum.each(State.get_elixir_modules(pid), fn {_module, info} ->
      walk_module(pid, info)
    end) 
  end

  defp walk_module(pid, %{ definitions: definitions }) do
    Enum.each(definitions, &walk_definition(pid, &1))
  end

  defp walk_definition(pid, {_fn, type, _meta, clauses}) when type in [:def, :defp] do
    Enum.each(clauses, fn {_meta, _args, _clauses, body} ->
      walk(pid, body)
    end)
  end

  defp walk(pid, {:__block__, _meta, block}) do
    Enum.each(block, &walk(pid, &1))
  end

  defp walk(pid, {{:., _meta1, [module, _func]}, _meta2, args}) do
    IO.inspect(module, label: "module")
    State.put_new_elixir_module(pid, module, nil)
    
    if is_list(args) do
      Enum.each(args, &walk(pid, &1))
    end
  end

  defp walk(pid, {:., _meta1, {module, _func}, _meta2, args}) do
    State.put_new_elixir_module(pid, module, nil)
    
    if is_list(args) do
      Enum.each(args, &walk(pid, &1))
    end  
  end

  defp walk(pid, {:., _meta, [module, _func]}) when module != :erlang do
    State.put_new_elixir_module(pid, module, nil)
  end

  defp walk(pid, {name, _meta, args}) when is_atom(name) do
    if is_list(args) do
      Enum.each(args, &walk(pid, &1))
    end
  end

  defp walk(_pid, unknown) do
    IO.inspect(unknown, label: "unknown")
  end
end

