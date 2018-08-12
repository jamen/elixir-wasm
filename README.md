
# elixir-wasm

Functions and types for [the WASM binary format](http://webassembly.github.io/spec/core/bikeshed/index.html#binary-format%E2%91%A0) (similar in purpose to [elixir-estree](https://github.com/elixirscript/elixir-estree)).  Note **it doesn't translate Elixir to WASM** but enables the possibility. See [ElixirScript](https://github.com/elixirscript) for progress on that front.

## Install

Add it to as a `mix.exs` dependency:

```elixir
{:wasm, "~> 0.1.0"}
```

## Documentation

See the [Hexdocs](https://hexdocs.pm/wasm).

## Testing

You must have [WABT](https://github.com/WebAssembly/wabt) to run `mix test`.  It uses `wat2wasm` to compare WAT-compiled WASM and Elixir-compiled WASM.

You can find the binaries at `_build/test/*.wasm` to use with WABT tools, `hexdump`, `xxd`, etc.
