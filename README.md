
# Elixir WASM

> Modules for using WASM with Elixir

Defines an [IR](https://en.wikipedia.org/wiki/Intermediate_representation) [for Web Assembly](http://webassembly.org/) made of tuples and atoms, like [Elixir's AST](http://elixir-lang.org/getting-started/meta/quote-and-unquote.html) or [Erlang's absform](http://erlang.org/doc/apps/erts/absform.html).  Has modules for encoding, decoding, typing, validating, and creating WASM modules. See [Roadmap](#roadmap) below for what is done so far.

**Note:** This is untested and unstable.  Not production ready!

## Roadmap
  
 - `WASM.Binary`
   - `WASM.Binary.encode` _Drafted_
   - `WASM.Binary.decode`
 - `WASM.IR`
 - `WASM.Validation`
 - `WASM`
   - `%WASM.Module{}`
   - `WASM.encode`
   - `WASM.decode`
 - Finish tests

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

 - [`WASM`](https://hexdocs.pm/wasm/WASM)
 - [`WASM.Binary`](https://hexdocs.pm/wasm/WASM.Binary)
 - TODO: `WASM.Module`
 - TODO: `WASM.Validation`

Extra modules (may be republished)

 - [`WASM.LEB128`](https://hexdocs.pm/wasm/WASM.LEB128)

