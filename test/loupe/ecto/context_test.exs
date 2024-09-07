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

      assert {:ok,
              %Context{
                bindings: %{
                  [:external_keys] => :a0
                }
              }} = Context.put_bindings(context, [["external_keys", "external_id"]])

      assert {:ok,
              %Context{
                bindings: %{
                  [:posts] => :a1,
                  [:posts, :comments] => :a0,
                  [:posts, :comments, :author] => :a2
                }
              }} =
               Context.put_bindings(context, [
                 ["posts", "comments", "text"],
                 ["posts", "comments", "author", "name"]
               ])

      assert {:ok,
              %Context{
                bindings: %{
                  [:role] => :a0
                }
              }} =
               Context.put_bindings(context, [
                 ["role", "permissions", {:path, ["folders", "access"]}]
               ])
    end

    @tag assigns: %{role: "user"}
    test "returns an error if the binding is not allowed", %{context: context} do
      assert {:error, {:invalid_binding, "role"}} =
               Context.put_bindings(context, [["role", "slug"]])

      assert {:error, {:invalid_binding, "age"}} = Context.put_bindings(context, [["age"]])
    end
  end

  describe "selectable_fields/" do
    setup [
      :create_context,
      :with_root_schema
    ]

    test "gets selectable fields", %{context: context} do
      assert [:id, :name, :email, :age, :active, :bank_account, :role_id] =
               Context.selectable_fields(context)
    end
  end

  describe "selectable_fields/2" do
    setup [
      :create_context,
      :with_root_schema
    ]

    test "gets selectable fields", %{context: context} do
      assert [:id, :name, :email, :age, :active, :bank_account, :role_id] =
               Context.selectable_fields(context, User)
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

  describe "initialize_query/1" do
    setup [:create_context, :with_root_schema]

    @tag assigns: %{ordered_by_id: true}
    test "initializes a query through scope_schema/2", %{
      context: %Context{root_schema: root_schema} = context
    } do
      assert %Ecto.Query{} = Context.initialize_query(context)

      assert root_schema ==
               context
               |> update_assigns(%{})
               |> Context.initialize_query()
    end
  end

  describe "cast_sigil/3" do
    setup [:create_context, :with_root_schema]

    test "casts sigil using the implementation", %{context: context} do
      assert 40_000 = Context.cast_sigil(context, {'m', "400.00"})
      assert "other" = Context.cast_sigil(context, {'o', "other"})
    end
  end
end
