defmodule Loupe.Ecto.DefinitionTest do
  use Loupe.TestCase

  alias Loupe.Ecto.Definition
  alias Loupe.Test.Ecto, as: TestSchemas

  @implementation Loupe.Test.Ecto.Definition
  setup [:load_schemas]

  describe "get_fields/3" do
    test "gets field of a schema" do
      assert %{associations: associations, fields: fields} =
               Definition.get_fields(@implementation, TestSchemas.Post, assigns: %{role: "admin"})

      assert associations == %{comments: "Comment", moderator: "User"}

      Assertions.assert_lists_equal(
        [:title, :id, :score, :user_id, :moderator_id, :price, :body],
        fields
      )
    end

    test "gets field of a schema scoping by assigns" do
      assert %{associations: associations, fields: fields} =
               Definition.get_fields(@implementation, TestSchemas.Post,
                 assigns: %{role: "basic user"}
               )

      assert associations == %{moderator: "User"}
      Assertions.assert_lists_equal([:title, :body], fields)
    end

    test "gets field of a schema including many to many" do
      assert %{associations: associations, fields: fields} =
               Definition.get_fields(@implementation, TestSchemas.User, assigns: %{role: "admin"})

      assert associations == %{
               posts: "Post",
               role: "Role",
               user_external_keys: "UserExternalKey",
               external_keys: "ExternalKey"
             }

      Assertions.assert_lists_equal(
        [:id, :name, :email, :age, :active, :bank_account, :role_id],
        fields
      )
    end
  end

  describe "get_field_at/4" do
    test "gets nested field at path" do
      assigns = %{role: "admin"}

      assert {%{associations: associations, fields: fields}, _} =
               Definition.get_field_at(
                 @implementation,
                 "User",
                 ["posts", "comments"],
                 assigns: assigns
               )

      assert %{author: "User"} == associations
      Assertions.assert_lists_equal(fields, [:id, :text, :post_id, :author_id])
    end

    test "returns root fields for empty path" do
      assigns = %{role: "admin"}

      assert {%{associations: associations, fields: fields}, _} =
               Definition.get_field_at(@implementation, "User", [], assigns: assigns)

      assert %{
               external_keys: "ExternalKey",
               posts: "Post",
               role: "Role",
               user_external_keys: "UserExternalKey"
             } == associations

      Assertions.assert_lists_equal(fields, [
        :id,
        :name,
        :age,
        :email,
        :active,
        :bank_account,
        :role_id
      ])
    end

    test "returns no field for a non association" do
      assigns = %{role: "admin"}

      assert {%{associations: associations, fields: fields}, _} =
               Definition.get_field_at(
                 @implementation,
                 "User",
                 ["posts", "comments", "id"],
                 assigns: assigns
               )

      assert %{} == associations
      Assertions.assert_lists_equal(fields, [])
    end
  end
end
