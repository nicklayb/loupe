defmodule Loupe.Errors.ParserError do
  @moduledoc "An error that occured in the parser's step"
  defexception [:line, :message]

  alias Loupe.Errors.ParserError

  @type t :: %ParserError{line: integer(), message: any()}
end
