defmodule Loupe.Language do
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
      ast
    end
  end
end
