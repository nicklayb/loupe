defmodule Loupe.Language.GetAstTest do
  use Loupe.TestCase
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
end
