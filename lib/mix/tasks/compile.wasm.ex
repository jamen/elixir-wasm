
defmodule Mix.Tasks.Compile.Wasm do
  use Mix.Task

  @cli_options [
    switches: [
      input: :string,
      output: :string,
      output_type: :string
    ],
    aliases: [
      i: :input,
      o: :output,
      t: :output_type
    ]
  ]

  @default_options [
    input: "./web/**/*.ex",
    output: "./_build/app.js",
    output_type: :js
  ]

  def run(args) do
    config = Keyword.get(Mix.Project.config(), :wasm, [])
    opts = build_options(config, args)
    build(opts)
    :ok
  end

  def build(opts) do
    WASM.Compiler.compile(opts)
  end

  defp build_options(config, args) do
    {opts, _args, _invalid} = OptionParser.parse(args, @cli_options)
    
    # Merge defaults/options/config into one
    opts = Keyword.merge(@default_options, opts, &merge_new/3)
    opts = Keyword.merge(opts, config, &merge_new/3)

    # Infer output type
    output_type = (
      case Keyword.get(opts, :output_type) do
        "js" -> :js
        "wasm" -> :wasm
        "html" -> :html
        x when is_atom(x) -> x
          # Use path extension
        _ ->
          case Path.extname(Keyword.get(opts, :output)) do
            ".js" -> :js
            ".wasm" -> :wasm
            ".html" -> :html
            _ -> nil
          end
      end
    )
 
    Keyword.put(opts, :output_type, output_type)
  end

  defp merge_new(_k, v1, v2) do
    if is_nil(v2), do: v1, else: v2
  end  
end

