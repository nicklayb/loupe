defmodule Loupe.Language.AstTest do
  use Loupe.TestCase
  alias Loupe.Language
  alias Loupe.Language.Ast

  describe "new/3" do
    test "creates a get ast structure and converts charlist to string" do
      assert %Ast{
               action: "get",
               schema: "User",
               quantifier: :all,
               predicates: {:>, {:binding, ["age"]}, {:int, 10}}
             } = Ast.new('get', 'User', :all, {:>, {:binding, ['age']}, {:int, 10}})
    end

    test "creates any other ast structure and converts charlist to string" do
      assert %Ast{
               action: "ecto",
               schema: "User",
               quantifier: :all,
               predicates: {:>, {:binding, ["age"]}, {:int, 10}}
             } = Ast.new('ecto', 'User', :all, {:>, {:binding, ['age']}, {:int, 10}})
    end
  end

  describe "bindings/1" do
    @case ~s|get all User where (name = "John Doe") and (role.slug = "admin" or role.permissions.slug in ["read", "right"])|
    test "extracts bindings and composed bindings from predicates" do
      assert {:ok, %Ast{action: "get"} = ast} = Language.compile(@case)

      assert [
               ["role", "permissions", "slug"],
               ["role", "slug"],
               ["name"]
             ] == Ast.bindings(ast)
    end
  end
end
