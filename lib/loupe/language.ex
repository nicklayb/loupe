defmodule Loupe.Language do
  alias Loupe.Language.GetAst

  alias Loupe.Errors.ParserError
  alias Loupe.Errors.LexerError

  @type compile_error :: ParserError.t() | LexerError.t()

  @spec compile(String.t() | charlist()) :: {:ok, %GetAst{}} | compile_error()
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
