# Loupe

[![Coverage Status](https://coveralls.io/repos/github/nicklayb/loupe/badge.svg?branch=main)](https://coveralls.io/github/nicklayb/loupe?branch=main)
[![Elixir CI](https://github.com/nicklayb/loupe/actions/workflows/elixir.yml/badge.svg)](https://github.com/nicklayb/loupe/actions/workflows/elixir.yml)

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

The basic syntax has the following format

```
get [quantifier?] [schema] where [predicates]
```

- `quantifier` is how many records you want. You can provide a positive integer (`1`, `2`, `3` ...), a range (`1..10`, `10..20`, `50..100`) or `all`.
- `schema` needs to be an alphanumeric indentifier that you registered in the Definition (See [Ecto Usage](#ecto-usage) for exmaple).
- `predicates` needs to be a combinaison or operators and boolean operators.

### Cool stuff

You can use `k` and `m` quantifiers for numbers. Writing `get all User where money > 100k` translates to `get all User where money > 100000`.

### Operators

The are a couple of basic operators like `<`, `>`, `<=`, `>=`, `=`, `!=`.

But also some textual operators:

- `in` is used with lists, like `age in [18, 21]`
- `like` is used with strings and automatically wraps in `%`.

You can also use the keyword `:empty` as a null checker like `age :empty`.

Textual operators and `:empty` can be prefixed with `not` to negate the expression: `not like`, `not in`, `age not :empty`.

For boolean, the binding can be provided as is and prefixed by `not` for false. Example `where active` or `where not enabled`.

### Boolean Operators

So far, the syntax supprts `and` and `or` and use parenthese to scope the expressions.

## Ecto usage

### Create a Definition module

The Definition module is necessary for Loupe to work with your Ecto schema. In this module you define the schemas that are allowed to be queried and the fields that are permitted for querying.

All callbacks accepts a last argument called "assigns". The assigns are provided to you when evaluating the query allowing you to alter the defition. You could, for instance, add a user's role to the assign and use that role to filter out the allowed schemas so that only admins can query Users.

```elixir
defmodule MyApp.Loupe.Definition do
    @moduledoc """
    Example Ecto definition for the modules defined above.
    """
    @behaviour Loupe.Ecto.Definition

    @schemas %{
      "Post" => Post,
      "User" => User,
      "Role" => Role
    }

    @impl Loupe.Ecto.Definition
    def schemas(%{role: "admin"}), do: @schemas
    def schemas(_), do: Map.take(@schemas, ["Post", "User"])

    @impl Loupe.Ecto.Definition
    def schema_fields(_, %{role: "admin"}), do: :all
    def schema_fields(Post, _), do: {:only, [:title, :body]}
    def schema_fields(User, _), do: {:only, [:email, :posts]}
    def schema_fields(_, _), do: :all

    @impl Loupe.Ecto.Definition
    def scope_schema(schema, _), do: schema
end
```

Once you have this definition, you can try some queries

```elixir
{:ok, ast} = Loupe.Language.compile(~s|get all User where age > 18|)
{:ok, ecto_query} = Loupe.Ecto.build_query(ast, MyApp.Loupe.Definition, %{role: "admin"})
Repo.all(ecto_query)
```

## Todo

Here are some things that I would like Loupe to support:

- Sorting a query, current ideas involves
  - `get all User order asc inserted_at`
  - `get all User where age > 10 ordered asc inserted_at`.
- Support some more complex fields prefixed by ~ (or whatever syntax, inspired by elixir's sigils) like the examples below
  - `get all Product where price = ~99.99$` and have that use the Elixir money lib.
  - `get all Item where ratio = ~1/4`
- Replace SQLite in test for Postgres and replace `like` for `ilike` in the Ecto Query builder. It has been done like that to avoid messing around with a postgres container only for test but I think it's better to go that route for maximum featureset.
- Implement a LiveView UI lib that shows the strucutres as expandable. Being able to click on a User's `posts` to automatically preload all of its nested Posts.
  - Also have "block" UI module where you can simply create a query from dropdowns in a form for non-power user.
- Make lexer and parser swappable. Right now, you are stuck with the internal structure that I came up with. The idea would be to allow some to swap the syntax for anything they want. For instance, a french team could implement a french query language to give to their normal user.

## Contributing

You can see the `CONTRIBUTING.md` file to know more about the contributing guidelines.

Pull requests are welcome!
