defmodule Loupe.Language do
  @moduledoc """
  Loupe's compiler entrypoint.
  """
  alias Loupe.Language.GetAst

  alias Loupe.Errors.LexerError
  alias Loupe.Errors.ParserError

  @type compile_error :: ParserError.t() | LexerError.t()

  @doc "Compiles a query to AST"
  @spec compile(String.t() | charlist()) :: {:ok, GetAst.t()} | compile_error()
  def compile(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> compile()
  end

  def compile(charlist) do
    with {:ok, tokens, _} <- :lexer.string(charlist),
         {:ok, ast} <- :parser.parse(tokens) do
      {:ok, new_ast(ast)}
    else
      {:error, {line, :parser, messages}} -> %ParserError{line: line, message: messages}
      {:error, {line, :lexer, messages}} -> %LexerError{line: line, message: messages}
    end
  end

  defp new_ast({:get, quantifier, schema, predicates}) do
    GetAst.new(schema, quantifier, predicates)
  end
end
