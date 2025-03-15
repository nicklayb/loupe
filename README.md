# Loupe

[![Coverage Status](https://coveralls.io/repos/github/nicklayb/loupe/badge.svg?branch=main)](https://coveralls.io/github/nicklayb/loupe?branch=main)
[![Elixir CI](https://github.com/nicklayb/loupe/actions/workflows/elixir.yml/badge.svg)](https://github.com/nicklayb/loupe/actions/workflows/elixir.yml)

Loupe is query language for Ecto schema inspection in a safe and configurable manner.

You can see [this example app](https://github.com/nicklayb/loupe_example) to understand how it applies with Ecto.

## Important

Until Loupe reaches `1.x.x`, it's considered experimental. The syntax will change, APIs will change and structure will too. We'll do our best to respect semantic versioning and avoid big breaking changes but they can happen.

## Installation

Loupe is [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `loupe` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:loupe, "~> 0.10.0"}
  ]
end
```

Thhe documentation can be found at <https://hexdocs.pm/loupe>.

## Syntax

The basic syntax has the following format

```
get [quantifier?] [schema][parameters?] where [predicates]
```

- `quantifier` is how many records you want. You can provide a positive integer (`1`, `2`, `3` ...), a range (`1..10`, `10..20`, `50..100`) or `all`.
- `schema` can be an alphanumeric indentifier that you registered in the Definition (See [Ecto Usage](#ecto-usage) for exmaple). The schema is required only for Ecto usage.
- `parameters` is a json inspired map. It takes the format of `{key: "value"}`. Key is an identifier, but value can be any literal type (another object, string, int, float, boolean, list)
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

### Field variant

Recently, support for "field variant" has been added. It's a syntax that allows to "customize" a field. The Ecto implementation uses the variant to query composite fields. Assume you have a composite Postgres field that is Money (like the [Money.Ecto.Composite.Type](https://hexdocs.pm/money/Money.Ecto.Composite.Type.html) type from the Money lib), you can now do the following to query the amount:

```
get User where bank_account:amount >= 1k
```

### Path binding

Loupe now supports "Path binding", being able to specify a path (like a json path) on a field. This is used by te Ecto implementation to query json field like below:

```
get User where role.permissions[posts, access] = "write"
# or
get User where role.permissions["posts", "access"] = "write"
```

### Variables and external identifiers

#### Query variable

The library allows you to provide external data to you query. Any identifier (unquote alphanumerical and underscore values) provided on the right side of an operator will be output as such. Taking for instance the Ecto implementation, it allows you to provide external parameter to the query. 

A good usecase example could be to automatically provide a `user_id` based from the authenticated user. So you can use it like:

```
get Posts where author_id = user_id
```

Then when evaluating the query you make sure to provide the user id by doing

```
Loupe.Ecto.build_query(query, EctoDefinition, %{}, %{"user_id" => current_user.id})
```

*Note*: Variables in query are *required*. When evaluating if the query uses a variable that is not provided, an error will be raise.

#### Parameters

This variables can also be used in parameters. Suppose your implementation supports an `order_by` parameter, you can use it like

```
get Posts{order_by: {direction: direction, field: field}}
```

Unlike variables, they don't need to be provided, they are simply extract as such and it's up to you to manipulate them the way you want. For the case of the Ecto implementation, however, they do need to be implemented so they can be extracted in the returning context.

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

## Stream / Enumerable

Support has been added to filter streams or enumerable.

The same features applies and some more extra;

- You can use a quantifier to limit the stream (`get 3 ...`)
- You can override the whole comparison logic
- You can use field variant as "modifier" through a custom `Loupe.Stream.Comparator` implementation.
- You can use sigil for more complex comparison

### Example

```elixir
posts = [
  %{title: "My post", comments: [%{comment: "Boring!", author: "Homer Simpsons"}]},
  %{title: "My second post", comments: [%{comment: "Respect my authorita!", author: "Eric Cartman"}]},
]
{:ok, stream} = Loupe.Stream.query(~s|get where comments.author like "Eric"|, posts)
[%{title: "My second posts"}] = Enum.to_list(stream)
```

## Todo

Here are some things that I would like Loupe to support:

- ~Sorting a query, current ideas involves~
  - This can be achieve with a parameter like `get User{order_by: "age"} where ...` and be handled manually by your application
- ~Support some more complex fields prefixed by ~ (or whatever syntax, inspired by elixir's sigils) like the examples below~
  - This has been implemented. Field variants can be used for composite fields and sigil can be used for expresions.
- Implement a LiveView UI lib that shows the strucutres as expandable. Being able to click on a User's `posts` to automatically preload all of its nested Posts.
  - Also have "block" UI module where you can simply create a query from dropdowns in a form for non-power user.
- Make lexer and parser swappable. Right now, you are stuck with the internal structure that I came up with. The idea would be to allow some to swap the syntax for anything they want. For instance, a french team could implement a french query language to give to their normal user.

## Contributing

You can see the `CONTRIBUTING.md` file to know more about the contributing guidelines.

Pull requests are welcome!

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/D1D2YX9OU)
