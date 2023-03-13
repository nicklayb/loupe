defmodule Loupe.Ecto.ContextTest do
  use Loupe.TestCase

  alias Loupe.Ecto.Context
  alias Loupe.Test.Ecto.User
  alias Loupe.Test.Ecto.Post
  alias Loupe.Test.Ecto.Role

  @implementation Loupe.Test.Ecto.Definition

  setup [:load_schemas]

  describe "new/2" do
    test "instanciate a context from assigns and implementation" do
      assigns = %{role: "admin"}

      assert %Context{
               assigns: ^assigns,
               implementation: @implementation,
               root_schema: nil,
               bindings: %{}
             } = Context.new(@implementation, assigns)
    end
  end

  describe "put_root_schema/2" do
    setup [:create_context]

    test "puts root schema if valid ecto schema key", %{context: context} do
      assert {:ok, %Context{root_schema: User}} = Context.put_root_schema(context, "User")
    end

    test "returns error if not an ecto schema", %{context: context} do
      assert {:error, :invalid_schema} = Context.put_root_schema(context, "Nothing")
      assert {:error, :invalid_schema} = Context.put_root_schema(context, String)
      assert {:error, :invalid_schema} = Context.put_root_schema(context, nil)
    end

    @tag assigns: %{role: "user"}
    test "returns error if the schema is not allowed", %{context: context} do
      assert {:error, :invalid_schema} = Context.put_root_schema(context, "Role")
    end
  end

  describe "put_bindings/2" do
    setup [
      :create_context,
      :with_root_schema
    ]

    test "puts bindings if all valid", %{context: context} do
      assert {:ok,
              %Context{
                bindings: %{
                  [:role] => :a0
                }
              }} = Context.put_bindings(context, [["role", "slug"], ["email"]])

      assert {:ok,
              %Context{
                bindings: %{
                  [:posts] => :a0
                }
              }} = Context.put_bindings(context, [["posts", "title"]])

      {:ok, context} = Context.put_root_schema(context, "Post")

      assert {:ok,
              %Context{
                bindings: %{
                  [:user, :role] => :a0,
                  [:user] => :a1
                }
              }} = Context.put_bindings(context, [["user", "role", "slug"], ["user", "email"]])
    end

    @tag assigns: %{role: "user"}
    test "returns an error if the binding is not allowed", %{context: context} do
      assert {:error, {:invalid_binding, "role"}} =
               Context.put_bindings(context, [["role", "slug"]])

      assert {:error, {:invalid_binding, "age"}} = Context.put_bindings(context, [["age"]])
    end
  end

  describe "schemas/1" do
    setup [:create_context]

    test "lists implementation's schemas", %{context: context} do
    end
  end

  defp create_context(test_context) do
    assigns = Map.get(test_context, :assigns, %{role: "admin"})

    [context: Context.new(@implementation, assigns)]
  end

  defp with_root_schema(%{context: context} = test_context) do
    root_schema_key = Map.get(test_context, :root_schema, "User")
    %{^root_schema_key => root_schema} = Context.schemas(context)
    [_ | _] = root_schema.__schema__(:fields)
    {:ok, context} = Context.put_root_schema(context, root_schema_key)
    [context: context]
  end

  defp load_schemas(_) do
    Enum.each([User, Role, Post], fn schema ->
      schema.__schema__(:fields)
      schema.__schema__(:associations)
    end)

    :ok
  end
end
