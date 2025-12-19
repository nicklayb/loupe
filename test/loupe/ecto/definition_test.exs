defmodule Loupe.Ecto.DefinitionTest do
  use Loupe.TestCase

  alias Loupe.Ecto.Definition
  alias Loupe.Test.Ecto, as: TestSchemas

  @implementation Loupe.Test.Ecto.Definition
  setup [:load_schemas]

  describe "get_fields/2" do
    test "gets field of a schema" do
      assert %{associations: associations, fields: fields} =
               Definition.get_fields(@implementation, TestSchemas.Post, %{role: "admin"})

      assert associations == %{comments: "Comment", moderator: "User"}

      Assertions.assert_lists_equal(
        [:title, :id, :score, :user_id, :moderator_id, :price, :body],
        fields
      )
    end

    test "gets field of a schema scoping by assigns" do
      assert %{associations: associations, fields: fields} =
               Definition.get_fields(@implementation, TestSchemas.Post, %{role: "basic user"})

      assert associations == %{moderator: "User"}
      Assertions.assert_lists_equal([:title, :body], fields)
    end

    test "gets field of a schema including many to many" do
      assert %{associations: associations, fields: fields} =
               Definition.get_fields(@implementation, TestSchemas.User, %{role: "admin"})

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
end
