defmodule Loupe.Ecto.ContextTest do
  use Loupe.TestCase

  alias Loupe.Ecto.Context
  alias Loupe.Test.Ecto.User

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

      assert {:ok,
              %Context{
                bindings: %{
                  [:posts, :comments] => :a0,
                  [:posts] => :a1
                }
              }} = Context.put_bindings(context, [["posts", "comments", "text"]])
    end

    @tag assigns: %{role: "user"}
    test "returns an error if the binding is not allowed", %{context: context} do
      assert {:error, {:invalid_binding, "role"}} =
               Context.put_bindings(context, [["role", "slug"]])

      assert {:error, {:invalid_binding, "age"}} = Context.put_bindings(context, [["age"]])
    end
  end

  describe "sorted_bidings/1" do
    setup [
      :create_context,
      :with_root_schema
    ]

    test "gets sorted bindings by path length", %{context: context} do
      assert {:ok, %Context{} = context} =
               Context.put_bindings(context, [["posts", "comments", "text"]])

      assert [{[:posts], :a1}, {[:posts, :comments], :a0}] = Context.sorted_bindings(context)
    end
  end
end