defmodule Loupe.LanguageTest do
  use Loupe.TestCase
  alias Loupe.Language
  alias Loupe.Language.GetAst

  describe "compile/1" do
    @case ~s|get all User where email = "user@email.com"|
    test "compiles a string" do
      assert {:ok,
              %GetAst{
                schema: "User",
                predicates: {:=, {:binding, ["email"]}, {:string, "user@email.com"}},
                quantifier: :all
              }} = Language.compile(@case)
    end
  end

  describe "compile/1 quantifier" do
    @case ~s|get all User where email = "user@email.com"|
    test "supports :all as a quantifier" do
      assert {:ok, %GetAst{quantifier: :all}} = Language.compile(@case)
    end

    @case ~s|get 1..10 User where email = "user@email.com"|
    test "supports range as a quantifier" do
      assert {:ok, %GetAst{quantifier: {:range, {1, 10}}}} = Language.compile(@case)
    end

    @case ~s|get 1 User where email = "user@email.com"|
    test "supports positive integer as a quantifier" do
      assert {:ok, %GetAst{quantifier: {:int, 1}}} = Language.compile(@case)
    end

    @case ~s|get User where email = "user@email.com"|
    test "supports no quantifier as 1" do
      assert {:ok, %GetAst{quantifier: {:int, 1}}} = Language.compile(@case)
    end
  end

  describe "compile/1 predicates" do
    @case ~s|get User where age > 18|
    test "supports > operator" do
      assert {:ok, %GetAst{predicates: {:>, {:binding, ["age"]}, {:int, 18}}}} =
               Language.compile(@case)
    end

    @case ~s|get User where age < 18|
    test "supports < operator" do
      assert {:ok, %GetAst{predicates: {:<, {:binding, ["age"]}, {:int, 18}}}} =
               Language.compile(@case)
    end

    @case ~s|get User where age = 18|
    test "supports = operator" do
      assert {:ok, %GetAst{predicates: {:=, {:binding, ["age"]}, {:int, 18}}}} =
               Language.compile(@case)
    end

    @case ~s|get User where age <= 18|
    test "supports <= operator" do
      assert {:ok, %GetAst{predicates: {:<=, {:binding, ["age"]}, {:int, 18}}}} =
               Language.compile(@case)
    end

    @case ~s|get User where age >= 18|
    test "supports >= operator" do
      assert {:ok, %GetAst{predicates: {:>=, {:binding, ["age"]}, {:int, 18}}}} =
               Language.compile(@case)
    end

    @case ~s|get User where email like "something"|
    test "supports like operator" do
      assert {:ok, %GetAst{predicates: {:like, {:binding, ["email"]}, {:string, "something"}}}} =
               Language.compile(@case)
    end

    @case ~s|get User where role.slug = "admin"|
    test "supports composed bindings" do
      assert {:ok, %GetAst{predicates: {:=, {:binding, ["role", "slug"]}, {:string, "admin"}}}} =
               Language.compile(@case)
    end

    @case ~s|get User where role.slug in ["admin", "user"]|
    test "supports in list operand" do
      assert {:ok,
              %GetAst{
                predicates:
                  {:in, {:binding, ["role", "slug"]},
                   {:list, [{:string, "admin"}, {:string, "user"}]}}
              }} = Language.compile(@case)
    end

    @case ~s|get User where age = 18 or name = "Bob"|
    test "supoprts or boolean operator" do
      assert {:ok,
              %GetAst{
                predicates:
                  {:or, {:=, {:binding, ["age"]}, {:int, 18}},
                   {:=, {:binding, ["name"]}, {:string, "Bob"}}}
              }} = Language.compile(@case)
    end

    @case ~s|get User where age = 18 and name = "Bob"|
    test "supports and boolean operatand" do
      assert {:ok,
              %GetAst{
                predicates:
                  {:and, {:=, {:binding, ["age"]}, {:int, 18}},
                   {:=, {:binding, ["name"]}, {:string, "Bob"}}}
              }} = Language.compile(@case)
    end

    @case ~s|get User where (age = 18 and name = "Bob") or (age > 50)|
    test "supports scoped boolean operatand" do
      assert {:ok,
              %GetAst{
                predicates:
                  {:or,
                   {:and, {:=, {:binding, ["age"]}, {:int, 18}},
                    {:=, {:binding, ["name"]}, {:string, "Bob"}}},
                   {:>, {:binding, ["age"]}, {:int, 50}}}
              }} = Language.compile(@case)
    end
  end
end
