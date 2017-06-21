
# Elixir WASM

> Build and compile WASM IR for Elixir

A module that encodes an [IR](https://en.wikipedia.org/wiki/Intermediate_representation) [for Web Assembly](http://webassembly.org/) that is inspired from [Elixir's quoted expressions](http://elixir-lang.org/getting-started/meta/quote-and-unquote.html) and [Erlang's absform](http://erlang.org/doc/apps/erts/absform.html) so it is familiar :smile:

**Note:** This is untested and very unstable.  Not production ready

 - [x] [Binary Format](http://webassembly.github.io/spec/binary)
 - [ ] [Validation](http://webassembly.github.io/spec/validation/index.html)
 - [ ] Unit tests

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

