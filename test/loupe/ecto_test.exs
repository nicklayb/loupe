defmodule Loupe.EctoTest do
  use Loupe.TestCase, async: false

  alias Loupe.Ecto, as: LoupeEcto
  alias Loupe.Test.Ecto.Comment
  alias Loupe.Test.Ecto.ExternalKey
  alias Loupe.Test.Ecto.Post
  alias Loupe.Test.Ecto.Repo
  alias Loupe.Test.Ecto.Role
  alias Loupe.Test.Ecto.User
  alias Loupe.Test.Ecto.UserExternalKey

  @implementation Loupe.Test.Ecto.Definition

  setup_all [
    :start_repo,
    :setup_entities,
    :checkout_repo
  ]

  describe "build_query/1" do
    test "builds query from string without assigns" do
      assert [
               %User{email: "user@email.com"}
             ] = run_query(~s|get all User where email = "user@email.com"|, nil)
    end

    test "builds query with raw ast" do
      assert {:ok, ast} = Loupe.Language.compile(~s|get all User where email = "user@email.com"|)

      assert [
               %User{email: "user@email.com"}
             ] = run_query(ast)
    end

    test "builds query joining multiple time the same binding" do
      assert [
               %User{email: "another_user@email.com"}
             ] =
               run_query("""
               get all User 
               where (
                 posts.title like "post"
                 and posts.score > 0.5
               )
               """)
    end

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

    test "builds query with integer quantifier" do
      assert [%User{email: "user@email.com"}] =
               run_query(~s(get 1 User where email not :empty), %{
                 role: "admin",
                 ordered_by_id: true
               })

      assert [%User{email: "user@email.com"}, %User{email: "something@gmail.com"}] =
               run_query(~s(get 2 User where email not :empty), %{
                 role: "admin",
                 ordered_by_id: true
               })
    end

    test "builds query with range quantifier" do
      assert [%User{email: "user@email.com"}] =
               run_query(~s(get 0..1 User where email not :empty), %{
                 role: "admin",
                 ordered_by_id: true
               })

      assert [%User{email: "something@gmail.com"}] =
               run_query(~s(get 1..2 User where email not :empty), %{
                 role: "admin",
                 ordered_by_id: true
               })

      assert [%User{email: "something@gmail.com"}, %User{email: "another_user@email.com"}] =
               run_query(~s(get 1..3 User where email not :empty), %{
                 role: "admin",
                 ordered_by_id: true
               })
    end

    test "queries using and operator" do
      assert [
               %User{email: "another_user@email.com"}
             ] = run_query(~s|get all User where age > 18 and age < 30|)
    end

    test "queries float" do
      assert [
               %Post{score: 1.5}
             ] = run_query(~s|get all Post where score > 0.5|)
    end

    test "queries using or operator" do
      assert [_, _] = results = run_query(~s|get all User where age < 20 or age > 29|)
      assert Enum.any?(results, &match?(%User{email: "something@gmail.com"}, &1))
      assert Enum.any?(results, &match?(%User{email: "user@email.com"}, &1))
    end

    test "queries using sigil" do
      assert [%User{bank_account: 400_000}] =
               run_query(~s|get all User where bank_account > ~m"400.00"|)
    end

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

    test "selects has_many through relation" do
      assert [
               %User{name: "Jane Doe", email: "user@email.com"}
             ] =
               run_query(~s|get all User where external_keys.external_id = "janedoe"|, %{
                 role: "admin"
               })
    end

    test "selects only allowed fields" do
      assert [
               %User{name: "Jane Doe", email: "user@email.com"}
             ] = run_query(~s|get all User where email = "user@email.com"|, %{role: "admin"})

      assert [
               %User{name: nil, email: "user@email.com"}
             ] = run_query(~s|get all User where email = "user@email.com"|, %{role: "user"})
    end

    test "returns error if query field is not allowed" do
      assert {:error, {:invalid_binding, "name"}} =
               LoupeEcto.build_query(
                 ~s|get all User where name = "John Doe"|,
                 @implementation,
                 %{role: "user"}
               )
    end
  end

  defp setup_entities(_) do
    Repo.insert!(%User{
      role: %Role{slug: "admin"},
      email: "user@email.com",
      name: "Jane Doe",
      bank_account: 1_000,
      age: 18,
      posts: [
        %Post{
          title: "My post",
          comments: [
            %Comment{text: "That's something"}
          ]
        }
      ],
      user_external_keys: [
        %UserExternalKey{
          external_key: %ExternalKey{external_id: "janedoe"}
        }
      ]
    })

    Repo.insert!(%User{
      age: 30,
      active: true,
      name: "John Doe",
      email: "something@gmail.com",
      bank_account: 400_000,
      role: %Role{slug: "user"},
      user_external_keys: [
        %UserExternalKey{
          external_key: %ExternalKey{external_id: "johndoe"}
        }
      ]
    })

    Repo.insert!(%User{
      role: %Role{slug: "admin"},
      email: "another_user@email.com",
      bank_account: 10_000,
      age: 21,
      posts: [
        %Post{
          title: "My amazing post",
          score: 1.5,
          comments: [
            %Comment{text: "That's a comment"}
          ]
        }
      ]
    })

    []
  end

  defp run_query(query, assigns \\ %{role: "admin"}) do
    result =
      case assigns do
        nil ->
          LoupeEcto.build_query(query, @implementation)

        _ ->
          LoupeEcto.build_query(
            query,
            @implementation,
            assigns
          )
      end

    assert {:ok, %Ecto.Query{} = ecto_query, _context} = result

    Repo.all(ecto_query)
  end
end
