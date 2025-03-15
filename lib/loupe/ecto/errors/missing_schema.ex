defmodule Loupe.Ecto.Errors.MissingSchemaError do
  @moduledoc "An error that occured in the lexer's step"
  defexception []

  alias Loupe.Ecto.Errors.MissingSchemaError

  @type t :: %MissingSchemaError{}

  @impl Exception
  def message(%MissingSchemaError{}) do
    "Ecto queries expect a schema, got nil"
  end
end
