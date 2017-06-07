
# Elixir WASM

> Build and compile WASM IR for Elixir

Defines an [IR](https://en.wikipedia.org/wiki/Intermediate_representation) for [Web Assembly](http://webassembly.org/) in Elixir, and functions for parsing and compiling `.wasm` binaries from it.  The WASM IR is inspired from [Elixir's quoted expressions](http://elixir-lang.org/getting-started/meta/quote-and-unquote.html) and [Erlang's absform](http://erlang.org/doc/apps/erts/absform.html) so it is familiar :smile:

**Note:** This is a work in progress, probably not usable in anything at the moment

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

### `WASM.compile(node)`

Compiles an IR node tree into a binary.

```js
binary = WASM.compile({:block, {:type, :block, :i32}, [
  {:div_s, :i32},
  {:eq, :i32}
]})
```
