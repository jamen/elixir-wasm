
# elixir-wasm

Functions and types for encoding WebAssembly.

For more information, see the [WebAssembly spec](https://github.com/WebAssembly/spec), the [Binary section](http://webassembly.github.io/spec/core/bikeshed/index.html#binary-format%E2%91%A0), and the [types documented for this module](https://hexdocs.pm/wasm/Wasm.html).

## Scope

This module **does not compile Elixir to WebAssembly**, it lets Elixir encode a WebAssembly module using tuples of instructions.

Please see [ElixirScript](https://github.com/elixirscript/elixirscript), where Elixir [will eventually](https://github.com/elixirscript/elixirscript/issues/454) compile to WebAssembly using this module.

## Documentation

See the [Hexdocs](https://hexdocs.pm/wasm).

## Testing

The tests compare Elixir-compiled WASM and WAT-compiled WASM using the command `wat2wasm` (from the [WebAssembly Binary Toolkit](https://github.com/WebAssembly/wabt)), so this needs to be installed or else the tests will fail.

After the tests, you can inspect the binaries at `_build/test/*.wasm` with `wasm2wat`, `hexdump`, etc.