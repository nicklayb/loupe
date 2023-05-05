defmodule Loupe.Fixture do
  @moduledoc "Tooling for writings tests"

  alias Loupe.Ecto.Context
  alias Loupe.Language
  alias Loupe.Language.Ast
  alias Loupe.Test.Ecto.Comment
  alias Loupe.Test.Ecto.ExternalKey
  alias Loupe.Test.Ecto.Post
  alias Loupe.Test.Ecto.Role
  alias Loupe.Test.Ecto.User
  alias Loupe.Test.Ecto.UserExternalKey

  @implementation Loupe.Test.Ecto.Definition

  def create_context(test_context) do
    assigns = Map.get(test_context, :assigns, %{role: "admin"})
    implementation = Map.get(test_context, :implementation, @implementation)

    [context: Context.new(implementation, assigns)]
  end

  def with_root_schema(%{context: context} = test_context) do
    root_schema_key = Map.get(test_context, :root_schema, "User")
    %{^root_schema_key => root_schema} = Context.schemas(context)
    [_ | _] = root_schema.__schema__(:fields)
    {:ok, context} = Context.put_root_schema(context, root_schema_key)
    [context: context]
  end

  def load_schemas(_) do
    # Not 100% sure why, but `__schema__/1` needs to be called once before `function_exported?/3` works.
    Enum.each([Comment, ExternalKey, UserExternalKey, User, Role, Post], fn schema ->
      schema.__schema__(:fields)
      schema.__schema__(:associations)
    end)

    :ok
  end

  def sigil_L(query, _) do
    {:ok, %Ast{} = ast} = Language.compile(query)

    ast
  end
end
