defmodule Loupe.Ecto.Filter.JsonPathTest do
  use Loupe.TestCase, async: false

  alias Loupe.Test.Ecto.User

  setup_all [
    :start_repo,
    :checkout_repo
  ]

  describe "apply_bounded_filter/3" do
    test "queries using thruty operator" do
      assert [
               %User{email: "something@gmail.com"}
             ] = run_query(~s|get all User where role.permissions["enabled"]|)
    end

    test "queries using falsy operator" do
      assert [
               %User{email: "something@gmail.com"}
             ] = run_query(~s|get all User where not role.permissions["disabled"]|)
    end

    test "queries using > operator" do
      assert [
               %User{email: "something@gmail.com"}
             ] = run_query(~s|get all User where role.permissions["folders", "id"] > 0|)
    end

    test "queries using >= operator" do
      assert [
               %User{email: "something@gmail.com"}
             ] = run_query(~s|get all User where role.permissions["folders", "id"] >= 1|)
    end

    test "queries using <= operator" do
      assert [
               %User{email: "something@gmail.com"}
             ] = run_query(~s|get all User where role.permissions["folders", "id"] <= 1|)
    end

    test "queries using < operator" do
      assert [
               %User{email: "something@gmail.com"}
             ] = run_query(~s|get all User where role.permissions["folders", "id"] < 2|)
    end

    test "queries using = operator" do
      assert [
               %User{email: "something@gmail.com"}
             ] = run_query(~s|get all User where role.permissions["folders", "access"] = "none"|)
    end

    test "queries using != operator" do
      assert [
               %User{email: "user@email.com"},
               %User{email: "something@gmail.com"}
             ] = run_query(~s|get all User where role.permissions["folders", "access"] != "read"|)
    end

    test "queries using like operator" do
      assert_raise(Loupe.Ecto.OperatorError, fn ->
        run_query(~s|get all User where role.permissions["folders", "access"] like "on"|)
      end)
    end

    test "queries using not like operator" do
      assert_raise(Loupe.Ecto.OperatorError, fn ->
        run_query(~s|get all User where role.permissions["folders", "access"] not like "ead"|)
      end)
    end

    test "queries using :empty keyword" do
      assert [
               %User{email: "another_user@email.com"}
             ] = run_query(~s|get all User where role.permissions["folders", "access"] :empty|)
    end

    test "queries using in operator" do
      assert [
               %User{email: "something@gmail.com"}
             ] = run_query(~s|get all User where role.permissions["folders", "id"] in [1, 2]|)
    end

    test "queries using not in operator" do
      assert [
               %User{email: "something@gmail.com"}
             ] = run_query(~s|get all User where role.permissions["folders", "id"] not in [2, 3]|)
    end

    test "queries using not :empty keyword" do
      assert [
               %User{email: "user@email.com"},
               %User{email: "something@gmail.com"}
             ] =
               run_query(~s|get all User where role.permissions["folders", "access"] not :empty|)
    end
  end
end
