
defmodule WASM.Compiler do
  @moduledoc false

  alias WASM.Compiler.State

  @doc """
  Start the compiler process with an input, output, and output type.

  The options specified are:
    - `:input` as a path or module name
    - `:output` as a file path
    - `:output_type` as `:js`, `:wasm`, or `:html`
  """
  @spec compile(Keyword.t) :: nil
  def compile(opts \\ []) do
    {:ok, pid} = State.start_link() 
    
    do_load(pid, opts[:input], opts)
  end

  # Compiling a path as input
  defp do_load(pid, input, opts) when is_binary(input) do
    files = Path.wildcard(input)

    Kernel.ParallelCompiler.files(files, [
      each_module: &on_module_compiled(pid, &1, &2, &3)
    ])

    do_compile(pid, opts)
  end

  # Compiling single module as input
  defp do_load(pid, input, opts) when is_atom(input) do
    State.put_elixir_module(pid, input, nil)
    do_compile(pid, opts)
  end

  # Compiling modules as input
  defp do_compile(pid, opts) do
    # Run passes
    WASM.Compiler.Find.execute(pid, opts)
    WASM.Compiler.Modules.execute(pid, opts)
    WASM.Compiler.Output.execute(pid, opts)

    # Generate output
    State.get_wasm_modules(pid)
    |> WASM.encode()
  end

  defp on_module_compiled(pid, _files, module, beam) do
    State.put_elixir_module(pid, module, beam)
  end
end

