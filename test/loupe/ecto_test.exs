defmodule Loupe.EctoTest do
  use Loupe.TestCase

  alias Loupe.Ecto, as: LoupeEcto
  alias Loupe.Test.Ecto.Comment
  alias Loupe.Test.Ecto.Post
  alias Loupe.Test.Ecto.Repo
  alias Loupe.Test.Ecto.Role
  alias Loupe.Test.Ecto.User

  @implementation Loupe.Test.Ecto.Definition

  setup [:setup_entities]

  describe "build_query/1" do
    test "builds query joining binding and applying predicates from string" do
      assert [
               %User{email: "user@email.com"}
             ] =
               run_query("""
               get all User 
               where (
                 posts.comments.text like "something" 
                 and role.slug = "admin"
               )
               """)
    end

    test "builds query joining binding and applying predicates" do
      assert [
               %User{email: "user@email.com"}
             ] =
               run_query(~L"""
               get all User 
               where (
                 posts.comments.text like "something" 
                 and role.slug = "admin"
               )
               """)
    end

    test "queries using thruty operator" do
      assert [
               %User{email: "something@gmail.com"}
             ] = run_query(~L|get all User where active|)
    end

    test "queries using falsy operator" do
      assert [
               %User{email: "user@email.com"},
               %User{email: "another_user@email.com"}
             ] = run_query(~L|get all User where not active|)
    end

    test "queries using > operator" do
      assert [
               %User{email: "something@gmail.com"}
             ] = run_query(~L|get all User where age > 25|)
    end

    test "queries using >= operator" do
      assert [
               %User{email: "something@gmail.com"}
             ] = run_query(~L|get all User where age >= 30|)
    end

    test "queries using <= operator" do
      assert [
               %User{email: "user@email.com"}
             ] = run_query(~L|get all User where age <= 18|)
    end

    test "queries using < operator" do
      assert [
               %User{email: "user@email.com"}
             ] = run_query(~L|get all User where age < 20|)
    end

    test "queries using = operator" do
      assert [
               %User{email: "user@email.com"}
             ] = run_query(~L|get all User where email = "user@email.com"|)
    end

    test "queries using != operator" do
      assert [
               %User{email: "something@gmail.com"}
             ] = run_query(~L|get all User where role.slug != "admin"|)
    end

    test "queries using like operator" do
      assert [
               %User{email: "something@gmail.com"}
             ] = run_query(~L|get all User where email like "gmail"|)
    end

    test "queries using not like operator" do
      assert [
               %User{email: "something@gmail.com"}
             ] = run_query(~L|get all User where email not like "email.com"|)
    end

    test "queries using :empty keyword" do
      assert [
               %User{email: "another_user@email.com"}
             ] = run_query(~L|get all User where name :empty|)
    end

    test "queries using in operator" do
      assert [
               %User{email: "user@email.com"},
               %User{email: "another_user@email.com"}
             ] = run_query(~L|get all User where age in [18, 21]|)
    end

    test "queries using not in operator" do
      assert [
               %User{email: "something@gmail.com"}
             ] = run_query(~L|get all User where age not in [18, 21]|)
    end

    test "queries using not :empty keyword" do
      assert [
               %User{email: "user@email.com"},
               %User{email: "something@gmail.com"}
             ] = run_query(~L|get all User where name not :empty|)
    end
  end

  defp setup_entities(_) do
    Repo.insert!(%User{
      role: %Role{slug: "admin"},
      email: "user@email.com",
      name: "Jane Doe",
      age: 18,
      posts: [
        %Post{
          title: "My post",
          comments: [
            %Comment{text: "That's something"}
          ]
        }
      ]
    })

    Repo.insert!(%User{
      age: 30,
      active: true,
      name: "John Doe",
      email: "something@gmail.com",
      role: %Role{slug: "user"}
    })

    Repo.insert!(%User{
      role: %Role{slug: "admin"},
      email: "another_user@email.com",
      age: 21,
      posts: [
        %Post{
          title: "My amzing post",
          comments: [
            %Comment{text: "Should not be fetched"}
          ]
        }
      ]
    })

    []
  end

  defp run_query(query, assigns \\ %{role: "admin"}) do
    assert {:ok, %Ecto.Query{} = ecto_query} =
             LoupeEcto.build_query(
               query,
               @implementation,
               assigns
             )

    Repo.all(ecto_query)
  end
end
