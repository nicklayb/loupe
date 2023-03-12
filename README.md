# Loupe

Loupe is query language for Ecto schema inspection in a safe and configurable manner.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `loupe` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:loupe, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/loupe>.

## Syntax

```
get all User where email = "user@email.com"
```

