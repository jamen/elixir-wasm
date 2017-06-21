
# Elixir WASM

> Build and compile WASM IR for Elixir

Modules that encode and validate an [IR](https://en.wikipedia.org/wiki/Intermediate_representation) [for Web Assembly](http://webassembly.org/) made of atoms and tuples (like [Elixir's AST](http://elixir-lang.org/getting-started/meta/quote-and-unquote.html) or [Erlang's absform](http://erlang.org/doc/apps/erts/absform.html))



**Note:** This is untested and very unstable.  Not production ready

 - [ ] [`WASM.Binary`](http://webassembly.github.io/spec/binary)
 - [ ] `WASM.Module`
 - [ ] [`WASM.Validation`](http://webassembly.github.io/spec/validation/index.html)
 - [ ] Unit tests
 - [ ] Typespecs

## Install

Add it to your deps inside `mix.exs`:

```elixir
{:wasm, "~> 0.1.0"}
```

Then run

```sh
mix deps.get
```

## Usage

See [wasm on hexdocs](https://hexdocs.pm/wasm) for docs on the `WASM.*` modules.

 - [`WASM.Binary`](https://hexdocs.pm/wasm/WASM.Binary)
 - `WASM.Module` (WIP)
 - `WASM.Validation` (WIP)

Extra modules (may be republished)

 - [`WASM.LEB128`](https://hexdocs.pm/wasm/WASM.LEB128)

