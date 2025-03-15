defmodule Loupe.Ecto.Errors.MissingSchemaError do
  @moduledoc "Error that occurs when to schema is provided but is expected"
  defexception []

  alias Loupe.Ecto.Errors.MissingSchemaError

  @type t :: %MissingSchemaError{}

  @impl Exception
  def message(%MissingSchemaError{}) do
    "Ecto queries expect a schema, got nil"
  end
end
