defmodule Loupe.Stream.ContextTest do
  use Loupe.TestCase, async: true

  alias Loupe.Stream.Context

  describe "new/1" do
    test "creates a new context" do
      assert %Context{
               parameters: %{},
               comparator: Loupe.Stream.DefaultComparator,
               variables: %{}
             } == Context.new()

      assert %Context{
               parameters: %{},
               comparator: SomeComparator,
               variables: %{"key" => "value"}
             } ==
               Context.new(
                 comparator: SomeComparator,
                 variables: %{"key" => "value"}
               )
    end
  end

  describe "apply_ast/2" do
    test "applies ast parameters" do
      assert {:ok, ast} =
               Loupe.Language.compile(
                 ~s|get all Keys{case: "lowercase"} where email like "hello"|
               )

      assert %Context{
               parameters: %{"case" => "lowercase"}
             } = Context.apply_ast(Context.new(), ast)
    end
  end

  describe "put_variables/2" do
    test "put variables in context" do
      context = Context.new(variables: %{"key" => "value"})

      assert %Context{
               variables: %{"other_key" => "other_value", "key" => "value"}
             } = Context.put_variables(context, %{"other_key" => "other_value"})
    end
  end
end
