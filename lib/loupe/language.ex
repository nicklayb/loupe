defmodule Loupe.Language do
  alias Loupe.Language.GetAst

  @sample ~s(
    get all Event where all
  )
  def parse, do: parse(@sample)

  def parse(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> parse()
  end

  def parse(charlist) do
    with {:ok, tokens, _} <- :lexer.string(charlist),
         {:ok, ast} <- :parser.parse(tokens) do
      new_ast(ast)
    end
  end

  defp new_ast({:get, quantifier, schema, predicates}) do
    GetAst.new(schema, quantifier, predicates)
  end
end
