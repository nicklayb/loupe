defmodule Loupe.LanguageTest do
  use Loupe.TestCase
  alias Loupe.Language
  alias Loupe.Language.Ast

  describe "compile/1" do
    @case ~s|get all User where email = "user@email.com"|
    test "compiles a string" do
      assert {:ok,
              %Ast{
                action: "get",
                schema: "User",
                predicates: {:=, {:binding, ["email"]}, {:string, "user@email.com"}},
                quantifier: :all
              }} = Language.compile(@case)
    end

    @case ~s|ecto all User where email = "user@email.com"|
    test "compiles a different action" do
      assert {:ok, %Ast{action: "ecto"}} = Language.compile(@case)
    end
  end

  describe "compile/1 quantifier" do
    @case ~s|get all User where email = "user@email.com"|
    test "supports :all as a quantifier" do
      assert {:ok, %Ast{quantifier: :all}} = Language.compile(@case)
    end

    @case ~s|get 1..10 User where email = "user@email.com"|
    test "supports range as a quantifier" do
      assert {:ok, %Ast{quantifier: {:range, {1, 10}}}} = Language.compile(@case)
    end

    @case ~s|get 1 User where email = "user@email.com"|
    test "supports positive integer as a quantifier" do
      assert {:ok, %Ast{quantifier: {:int, 1}}} = Language.compile(@case)
    end

    @case ~s|get User where email = "user@email.com"|
    test "supports no quantifier as 1" do
      assert {:ok, %Ast{quantifier: {:int, 1}}} = Language.compile(@case)
    end
  end

  describe "compile/1 predicates" do
    @case ~s|get Post where user_id = 1|
    test "supports underscored fields" do
      assert {:ok, %Ast{predicates: {:=, {:binding, ["user_id"]}, {:int, 1}}}} =
               Language.compile(@case)
    end

    @case ~s|get Post where age > 18|
    test "supports > operator" do
      assert {:ok, %Ast{predicates: {:>, {:binding, ["age"]}, {:int, 18}}}} =
               Language.compile(@case)
    end

    @case ~s|get User where age < 18|
    test "supports < operator" do
      assert {:ok, %Ast{predicates: {:<, {:binding, ["age"]}, {:int, 18}}}} =
               Language.compile(@case)
    end

    @case ~s|get User where age != 18|
    test "supports != operator" do
      assert {:ok, %Ast{predicates: {:!=, {:binding, ["age"]}, {:int, 18}}}} =
               Language.compile(@case)
    end

    @case ~s|get User where age = 18|
    test "supports = operator" do
      assert {:ok, %Ast{predicates: {:=, {:binding, ["age"]}, {:int, 18}}}} =
               Language.compile(@case)
    end

    @case ~s|get User where age <= 18|
    test "supports <= operator" do
      assert {:ok, %Ast{predicates: {:<=, {:binding, ["age"]}, {:int, 18}}}} =
               Language.compile(@case)
    end

    @case ~s|get User where age >= 18|
    test "supports >= operator" do
      assert {:ok, %Ast{predicates: {:>=, {:binding, ["age"]}, {:int, 18}}}} =
               Language.compile(@case)
    end

    @case ~s|get User where age :empty|
    test "supports :empty keyword" do
      assert {:ok, %Ast{predicates: {:=, {:binding, ["age"]}, :empty}}} = Language.compile(@case)
    end

    @case ~s|get User|
    test "supports queries without where" do
      assert {:ok, %Ast{predicates: nil}} = Language.compile(@case)
    end

    @case ~s|get all User|
    test "supports queries without where and quantifier" do
      assert {:ok, %Ast{predicates: nil}} = Language.compile(@case)
    end

    @case ~s|get User where age|
    test "supports thruty expression" do
      assert {:ok, %Ast{predicates: {:=, {:binding, ["age"]}, true}}} = Language.compile(@case)
    end

    @case ~s|get User where not age|
    test "supports falsy expression" do
      assert {:ok, %Ast{predicates: {:=, {:binding, ["age"]}, false}}} = Language.compile(@case)
    end

    @case ~s|get User where age not :empty|
    test "supports not :empty keyword" do
      assert {:ok, %Ast{predicates: {:!=, {:binding, ["age"]}, :empty}}} = Language.compile(@case)
    end

    @case ~s|get User where email like "something"|
    test "supports like operator" do
      assert {:ok, %Ast{predicates: {:like, {:binding, ["email"]}, {:string, "something"}}}} =
               Language.compile(@case)
    end

    @case ~s|get User where email not like "something"|
    test "supports not like operator" do
      assert {:ok,
              %Ast{predicates: {:not, {:like, {:binding, ["email"]}, {:string, "something"}}}}} =
               Language.compile(@case)
    end

    @case ~s|get User where role.slug = "admin"|
    test "supports composed bindings" do
      assert {:ok, %Ast{predicates: {:=, {:binding, ["role", "slug"]}, {:string, "admin"}}}} =
               Language.compile(@case)
    end

    @case ~s|get User where role.slug not in ["admin", "user"]|
    test "supports not in list operand" do
      assert {:ok,
              %Ast{
                predicates:
                  {:not,
                   {:in, {:binding, ["role", "slug"]},
                    {:list, [{:string, "admin"}, {:string, "user"}]}}}
              }} = Language.compile(@case)
    end

    @case ~s|get User where role.slug in ["admin", "user"]|
    test "supports in list operand" do
      assert {:ok,
              %Ast{
                predicates:
                  {:in, {:binding, ["role", "slug"]},
                   {:list, [{:string, "admin"}, {:string, "user"}]}}
              }} = Language.compile(@case)
    end

    @case ~s|get User where age = 18 or name = "Bob"|
    test "supoprts or boolean operator" do
      assert {:ok,
              %Ast{
                predicates:
                  {:or, {:=, {:binding, ["age"]}, {:int, 18}},
                   {:=, {:binding, ["name"]}, {:string, "Bob"}}}
              }} = Language.compile(@case)
    end

    @case ~s|get User where age = 18 and name = "Bob"|
    test "supports and boolean operand" do
      assert {:ok,
              %Ast{
                predicates:
                  {:and, {:=, {:binding, ["age"]}, {:int, 18}},
                   {:=, {:binding, ["name"]}, {:string, "Bob"}}}
              }} = Language.compile(@case)
    end

    @case ~s|get User where (age = 18 and name = "Bob") or (age > 50)|
    test "supports scoped boolean operand" do
      assert {:ok,
              %Ast{
                predicates:
                  {:or,
                   {:and, {:=, {:binding, ["age"]}, {:int, 18}},
                    {:=, {:binding, ["name"]}, {:string, "Bob"}}},
                   {:>, {:binding, ["age"]}, {:int, 50}}}
              }} = Language.compile(@case)
    end

    @failing_case ~s|get User where name = "d|
    test "intercepts raise errors" do
      assert {:error, %Loupe.Errors.LexerError{line: 1, message: {:illegal, '"d'}}} =
               Language.compile(@failing_case)
    end
  end
end
