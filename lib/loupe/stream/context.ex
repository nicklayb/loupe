defmodule Loupe.Stream.Context do
  @moduledoc """
  Context to work with Stream filtering
  """

  alias Loupe.Language.Ast
  alias Loupe.Stream.Context

  defstruct comparator: Loupe.Stream.DefaultComparator,
            parameters: %{},
            variables: %{}

  @type comparator :: module()

  @type t :: %Context{
          comparator: comparator(),
          parameters: Ast.parameters(),
          variables: map()
        }

  @default_comparator Loupe.Stream.DefaultComparator

  @type option :: {:comparator, comparator()}

  @doc "Creates a new context"
  @spec new([option()]) :: t()
  def new(options \\ []) do
    comparator = Keyword.get(options, :comparator, @default_comparator)
    variables = Keyword.get(options, :variables, %{})

    %Context{comparator: comparator, variables: variables}
  end

  @doc "Applies AST options in the context to prevent carrying the ast around"
  @spec apply_ast(t(), Ast.t()) :: t()
  def apply_ast(%Context{} = context, %Ast{} = ast) do
    %Context{context | parameters: ast.parameters}
  end

  @doc "Puts variable in context"
  @spec put_variables(t(), map()) :: t()
  def put_variables(%Context{variables: variables} = context, new_variables) do
    %Context{context | variables: Map.merge(variables, new_variables)}
  end
end
