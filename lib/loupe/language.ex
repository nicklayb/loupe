defmodule Loupe.Language do
  @moduledoc """
  Loupe's compiler entrypoint.
  """
  alias Loupe.Language.Ast

  alias Loupe.Errors.LexerError
  alias Loupe.Errors.ParserError

  @type compile_error :: ParserError.t() | LexerError.t()
  @type sigil_definition :: {char(), binary()}

  @doc "Compiles a query to AST"
  @spec compile(String.t() | charlist()) :: {:ok, Ast.t()} | {:error, compile_error()}
  def compile(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> compile()
  end

  def compile(charlist) do
    with {:ok, tokens, _} <- :loupe_lexer.string(charlist),
         {:ok, ast} <- :loupe_parser.parse(tokens) do
      {:ok, new_ast(ast)}
    else
      {:error, {line, :loupe_parser, messages}} ->
        {:error, %ParserError{line: line, message: messages}}

      {:error, {line, :loupe_lexer, messages}, _} ->
        {:error, %LexerError{line: line, message: messages}}
    end
  end

  defp new_ast({action, quantifier, {schema, parameters}, predicates}) do
    Ast.new(action, schema, quantifier, predicates, parameters)
  end
end
