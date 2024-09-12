defmodule Loupe.Ecto.OperatorError do
  @moduledoc """
  Error being raised where there is an error with operators
  """
  defexception [:operator, :binding, :message]
end
