defmodule Loupe.Language.GetAstTest do
  use Loupe.TestCase
  alias Loupe.Language
  alias Loupe.Language.GetAst

  describe "new/3" do
    test "creates a get ast structure and converts charlist to string" do
      assert %GetAst{
               schema: "User",
               quantifier: :all,
               predicates: {:>, {:binding, ["age"]}, {:int, 10}}
             } = GetAst.new('User', :all, {:>, {:binding, ['age']}, {:int, 10}})
    end
  end

  describe "bindings/1" do
    @case ~s|get all User where (name = "John Doe") and (role.slug = "admin" or role.permissions.slug in ["read", "right"])|
    test "extracts bindings and composed bindings from predicates" do
      assert {:ok, %GetAst{} = ast} = Language.compile(@case)

      assert [
               ["role", "permissions", "slug"],
               ["role", "slug"],
               ["name"]
             ] == GetAst.bindings(ast)
    end
  end
end
