
# elixir-wasm

Functions and types for encoding WebAssembly.

For more information, see the [WebAssembly spec](https://github.com/WebAssembly/spec), the [Binary section](http://webassembly.github.io/spec/core/bikeshed/index.html#binary-format%E2%91%A0), and the [types documented for this module](https://hexdocs.pm/wasm/Wasm.html).

## Scope

This module **does not compile Elixir to WebAssembly**, it lets Elixir encode a WebAssembly module using tuples that resemble the instructions.

Please see [ElixirScript](https://github.com/elixirscript/elixirscript), where Elixir [will eventually](https://github.com/elixirscript/elixirscript/issues/454) compile to WebAssembly using this module.

## Documentation

See the [Hexdocs](https://hexdocs.pm/wasm).

## Testing

The command wat2wasm` from [WABT](https://github.com/WebAssembly/wabt) needs to be available, because the tests compare Elixir-compiled WASM against WAT-compiled WASM for compatibility.

After the tests run, you can inspect the WebAssembly binaries at `_build/test/*.wasm` with `wasm2wat`, `hexdump`, etc.