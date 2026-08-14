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
             } = Ast.new(~c"get", ~c"User", :all, {:>, {:binding, [~c"age"]}, {:int, 10}})
    end

    test "creates any other ast structure and converts charlist to string" do
      assert %Ast{
               action: "ecto",
               schema: "User",
               quantifier: :all,
               predicates: {:>, {:binding, ["age"]}, {:int, 10}}
             } = Ast.new(~c"ecto", ~c"User", :all, {:>, {:binding, [~c"age"]}, {:int, 10}})
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

  describe "unwrap_literal/2" do
    test "unwraps literals" do
      assert {"string", %MapSet{}} = Ast.unwrap_literal({:string, ~c"string"}, MapSet.new())
      assert {12, %MapSet{}} = Ast.unwrap_literal({:int, 12}, MapSet.new())
      assert {12.5, %MapSet{}} = Ast.unwrap_literal({:float, 12.5}, MapSet.new())

      assert {{:sigil, {~c"m", "sigil"}}, %MapSet{}} =
               Ast.unwrap_literal({:sigil, {~c"m", ~c"sigil"}}, MapSet.new())

      assert {["string", 12, 12.5, {:sigil, {~c"m", "sigil"}}], %MapSet{}} =
               Ast.unwrap_literal(
                 {:list,
                  [
                    {:string, ~c"string"},
                    {:int, 12},
                    {:float, 12.5},
                    {:sigil, {~c"m", ~c"sigil"}}
                  ]},
                 MapSet.new()
               )

      assert {[{:identifier, "string"}], external_identifiers} =
               Ast.unwrap_literal({:list, [{:identifier, ~c"string"}]}, MapSet.new())

      assert MapSet.equal?(external_identifiers, MapSet.new(["string"]))

      assert {{:identifier, "string"}, external_identifiers} =
               Ast.unwrap_literal({:identifier, ~c"string"}, MapSet.new())

      assert MapSet.equal?(external_identifiers, MapSet.new(["string"]))
    end
  end
end
