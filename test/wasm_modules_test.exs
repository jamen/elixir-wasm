defmodule WasmModulesTest do
  use ExUnit.Case

  test "simple module" do
    assert_modules_equal(
      {:module,
       [
         type_sec: [
           {:func_type, [], [:i32]}
         ],
         func_sec: [
           {:type_index, 0}
         ],
         export_sec: [
           {:export, {:name, "test"}, {:func_index, 0}}
         ],
         code_sec: [
           {:code, {:func, [], {:expr, [{:i32_const, 1}, :return]}}}
         ]
       ]},
      """
        (module
            (func (export "test") (result i32)
              (i32.const 1)
              return
            )
        )
      """
    )
  end

  defp assert_modules_equal(wasm, wat) do
    id = :crypto.hash(:sha224, wat) |> Base.url_encode64(padding: false)
    wat_input = Path.join([Mix.Project.build_path(), "wat-" <> id <> ".wat"])
    wat_output = Path.join([Mix.Project.build_path(), "wat-" <> id <> ".wasm"])
    elixir_output = Path.join([Mix.Project.build_path(), "elixir-" <> id <> ".wasm"])
    File.write!(wat_input, wat)

    case System.cmd("wat2wasm", [wat_input, "-o", wat_output]) do
      {_msg, 0} ->
        wat_binary = File.read!(wat_output)
        elixir_binary = Wasm.encode(wasm)
        File.write!(elixir_output, elixir_binary)
        assert(wat_binary == elixir_binary)

      {msg, code} ->
        {:error, code, msg}
    end
  end
end
