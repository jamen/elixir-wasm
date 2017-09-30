
defmodule WASM.Compiler do
  @moduledoc false

  @initial_state %{
    modules: Keyword.new,
    wasm_modules: [],
    in_memory_modules: []
  }

  @doc """
  Start the compiler process with an input, output, and output type.

  The options specified are:
    - `:input` as a path or module name
    - `:output` as a file path
    - `:output_type` as `:js`, `:wasm`, or `:html`
  """
  @spec compile(Keyword.t) :: nil
  def compile(opts \\ []) do
    # Create compiler state
    {:ok, pid} = Agent.start_link(fn -> @initial_state end)

    # Compile the input
    do_compile(pid, opts[:input], opts)
  end

  # Compiling a path as input
  defp do_compile(pid, input, opts) when is_binary(input) do
    files = Path.wildcard(input)

    Kernel.ParallelCompiler.files(files, [
      each_module: &on_module_compiled(pid, &1, &2, &3)
    ])

    modules = pid
      |> Agent.get(fn(state) -> state.in_memory_modules end)
      |> Keyword.keys

    do_compile(pid, modules, opts)
  end

  # Compiling single module as input
  defp do_compile(pid, input, opts) when is_atom(input) do
    do_compile(pid, List.wrap(input), opts)
  end

  # Compiling modules as input
  defp do_compile(pid, input, opts) do
    WASM.Compiler.Find.execute(pid, input, opts)
    WASM.Compiler.Modules.execute(pid, input, opts)
    WASM.Compiler.Output.execute(pid, input, opts)
  end

  defp on_module_compiled(pid, _files, modules, beam) do
    Agent.update(pid, fn(state) ->
      in_memory_modules = Map.get(state, :in_memory_modules, [])
      in_memory_modules = Keyword.put(in_memory_modules, modules, beam)
      %{ state | in_memory_modules: in_memory_modules }
    end)
  end
end

