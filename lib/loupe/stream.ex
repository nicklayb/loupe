defmodule Loupe.Stream do
  @moduledoc """
  Filters a stream with Loupe's ast. Schema will likely have no impact 
  on the way this filtering is being done
  """

  alias Loupe.Language.Ast
  alias Loupe.Stream.Comparator
  alias Loupe.Stream.Context

  @type build_query_error :: any()

  @type option :: {:limit?, boolean()} | {:variables, map()} | Context.option()

  @doc """
  Queries a stream using an AST or a Query. The returned result will
  be an enumerable function to be executed with `Enum` functions.

  For stream queries, the Schema is unused, up to you to perform 
  pre-filtering, put a static one in place or omit it.

  ## Examples

  The following example will filter records whose age is greater than 18

      iex> {:ok, stream} = Loupe.Stream.query(~s|get where age > 18|, [
      ...>   %{age: 76},
      ...>   %{age: 13},
      ...>   %{age: 28},
      ...>   %{age: 6},
      ...>   %{age: 34},
      ...> ])
      iex> Enum.to_list(stream)
      [%{age: 76}]

  The same parsing rules applies here, so only one record is returned because 
  when quantifier is provided, it defaults to 1. One could use `all` to 
  get all the records that are matching or a range.

      iex> {:ok, stream} = Loupe.Stream.query(~s|get all where age > 18|, [
      ...>   %{age: 76},
      ...>   %{age: 13},
      ...>   %{age: 28},
      ...>   %{age: 6},
      ...>   %{age: 34},
      ...> ])
      iex> Enum.to_list(stream)
      [%{age: 76}, %{age: 28}, %{age: 34}]

      iex> {:ok, stream} = Loupe.Stream.query(~s|get 2..3 where age > 18|, [
      ...>   %{age: 76},
      ...>   %{age: 13},
      ...>   %{age: 28},
      ...>   %{age: 6},
      ...>   %{age: 34},
      ...> ])
      iex> Enum.to_list(stream)
      [%{age: 28}, %{age: 34}]

  ### Overriding query's limit

  In case you wanna enforce a limit of your own to the stream and don't wanna
  depend on the query's `quantifier`, you can pass `limit?: false` to the function

      iex> {:ok, stream} = Loupe.Stream.query(~s|get 1 where age > 18|, [
      ...>   %{age: 76},
      ...>   %{age: 13},
      ...>   %{age: 28},
      ...>   %{age: 6},
      ...>   %{age: 34},
      ...> ], limit?: false)
      iex> Enum.to_list(stream)
      [%{age: 76}, %{age: 28}, %{age: 34}]

  ### Using variables

  You can provide variables to your query with the `variables` option. Keys
  must be string to match what is decoded from the query.


      iex> {:ok, stream} = Loupe.Stream.query(~s|get 1 where age > adult|, [
      ...>   %{age: 76},
      ...>   %{age: 13},
      ...>   %{age: 28},
      ...>   %{age: 6},
      ...>   %{age: 34},
      ...> ], limit?: false, variables: %{"adult" => 18})
      iex> Enum.to_list(stream)
      [%{age: 76}, %{age: 28}, %{age: 34}]

  """
  @spec query(String.t() | Ast.t(), Enumerable.t(), [option()]) ::
          {:ok, Enumerable.t()} | {:error, build_query_error()}
  def query(string_or_ast, enumerable, options \\ [])

  def query(string, enumerable, options) when is_binary(string) do
    with {:ok, ast} <- Loupe.Language.compile(string) do
      query(ast, enumerable, options)
    end
  end

  def query(%Ast{quantifier: quantifier} = ast, enumerable, options) do
    variables = Keyword.get(options, :variables, %{})

    context =
      options
      |> Keyword.get_lazy(:context, fn -> Context.new(options) end)
      |> Context.apply_ast(ast)
      |> Context.put_variables(variables)

    stream =
      enumerable
      |> Stream.filter(&matches_ast?(ast, &1, context))
      |> maybe_limit_records(quantifier, options)

    {:ok, stream}
  end

  defp matches_ast?(%Ast{predicates: nil}, _element, _context) do
    true
  end

  defp matches_ast?(%Ast{predicates: predicates}, element, context) do
    Comparator.compare(predicates, element, context)
  end

  defp maybe_limit_records(enumerable, quantifier, options) do
    if Keyword.get(options, :limit?, true) do
      limit_records(enumerable, quantifier)
    else
      enumerable
    end
  end

  defp limit_records(enumerable, :all), do: enumerable
  defp limit_records(enumerable, {:int, integer}), do: Stream.take(enumerable, integer)

  defp limit_records(enumerable, {:range, {lower_bound, upper_bound}}) do
    lower_bound = lower_bound - 1

    enumerable
    |> Stream.drop(lower_bound)
    |> Stream.take(upper_bound - lower_bound)
  end
end
