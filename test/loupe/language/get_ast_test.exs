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

  describe "to_string/1" do
    test "stringifies a basic query" do
      query = ~s|get all User where role.slug = "admin"|
      assert {:ok, ast} = Language.compile(query)
      assert query == GetAst.to_string(ast)
    end
  end
end
