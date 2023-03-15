defmodule Loupe.Errors.LexerError do
  @moduledoc "An error that occured in the lexer's step"
  defexception [:line, :message]

  alias Loupe.Errors.LexerError

  @type t :: %LexerError{line: integer(), message: any()}
end
