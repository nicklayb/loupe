defmodule Loupe.Ecto.Filter.DirectTest do
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
             ] = run_query(~s|get all User where active|)
    end

    test "queries using falsy operator" do
      assert [
               %User{email: "user@email.com"},
               %User{email: "another_user@email.com"}
             ] = run_query(~s|get all User where not active|)
    end

    test "queries using > operator" do
      assert [
               %User{email: "something@gmail.com"}
             ] = run_query(~s|get all User where age > 25|)
    end

    test "queries using >= operator" do
      assert [
               %User{email: "something@gmail.com"}
             ] = run_query(~s|get all User where age >= 30|)
    end

    test "queries using <= operator" do
      assert [
               %User{email: "user@email.com"}
             ] = run_query(~s|get all User where age <= 18|)
    end

    test "queries using < operator" do
      assert [
               %User{email: "user@email.com"}
             ] = run_query(~s|get all User where age < 20|)
    end

    test "queries using = operator" do
      assert [
               %User{email: "user@email.com"}
             ] = run_query(~s|get all User where email = "user@email.com"|)
    end

    test "queries using != operator" do
      assert [
               %User{email: "something@gmail.com"}
             ] = run_query(~s|get all User where role.slug != "admin"|)
    end

    test "queries using like operator" do
      assert [
               %User{email: "something@gmail.com"}
             ] = run_query(~s|get all User where email like "gmail"|)
    end

    test "queries using not like operator" do
      assert [
               %User{email: "something@gmail.com"}
             ] = run_query(~s|get all User where email not like "email.com"|)
    end

    test "queries using :empty keyword" do
      assert [
               %User{email: "another_user@email.com"}
             ] = run_query(~s|get all User where name :empty|)
    end

    test "queries using in operator" do
      assert [
               %User{email: "user@email.com"},
               %User{email: "another_user@email.com"}
             ] = run_query(~s|get all User where age in [18, 21]|)
    end

    test "queries using not in operator" do
      assert [
               %User{email: "something@gmail.com"}
             ] = run_query(~s|get all User where age not in [18, 21]|)
    end

    test "queries using not :empty keyword" do
      assert [
               %User{email: "user@email.com"},
               %User{email: "something@gmail.com"}
             ] = run_query(~s|get all User where name not :empty|)
    end
  end
end
