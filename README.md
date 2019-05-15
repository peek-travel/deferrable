# Deferrable

**This is pre-release and will go through a couple more revisions before considered stable.**

Library for deferring execution of code until the completion of a transaction block.

Similar in concept to database transactions with support for nesting and partial-rollbacks.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `deferrable` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:deferrable, "~> 0.0.1"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/deferrable](https://hexdocs.pm/deferrable).

