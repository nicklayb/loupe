defmodule Loupe.Test.Ecto do
  @moduledoc """
  Mock schemas and Ecto modules for tests.

  For reasons I don't fully understand, seperating this module into
  seperate files causes compilation issues. Some module aren't loaded
  properly at the right time and cause problems. Same for some relations,
  those you see that uses `Module.concat/1`, they need to use this call 
  because at the time of reading this file, they aren't properly compiled.
  """

  alias Loupe.Ecto, as: LoupeEcto
  alias Loupe.Ecto.Context
  alias Loupe.Language
  alias Loupe.Language.Ast

  defmodule Repo do
    @moduledoc "Mocked repo"

    use Ecto.Repo,
      otp_app: :loupe,
      adapter: Ecto.Adapters.Postgres
  end

  defmodule Comment do
    @moduledoc "Comment schema"
    use Ecto.Schema

    schema("comments") do
      field(:text, :string)
      field(:post_id, :integer)

      belongs_to(:author, Module.concat(["Loupe", "Test", "Ecto", "User"]))
    end
  end

  defmodule Post do
    @moduledoc "Post schema"
    use Ecto.Schema

    schema("posts") do
      field(:title, :string)
      field(:body, :string)
      field(:user_id, :integer)
      field(:score, :float)

      field(:price, Money.Ecto.Composite.Type)

      belongs_to(:moderator, User)

      has_many(:comments, Comment)
    end
  end

  defmodule Role do
    @moduledoc "Post schema"
    use Ecto.Schema

    schema("roles") do
      field(:slug, :string)
      field(:permissions, :map)
    end
  end

  defmodule ExternalKey do
    @moduledoc "External key schema"
    use Ecto.Schema

    schema("external_keys") do
      field(:external_id)
    end
  end

  defmodule User do
    @moduledoc "Post schema"
    use Ecto.Schema

    schema("users") do
      field(:name, :string)
      field(:email, :string)
      field(:age, :integer)
      field(:active, :boolean)
      field(:bank_account, :integer)

      has_many(:posts, Post)
      has_many(:user_external_keys, Module.concat(["Loupe", "Test", "Ecto", "UserExternalKey"]))

      has_many(:external_keys, through: [:user_external_keys, :external_key])

      belongs_to(:role, Role)
    end
  end

  defmodule UserExternalKey do
    @moduledoc "User external key relation"
    use Ecto.Schema

    schema("user_external_keys") do
      belongs_to(:external_key, ExternalKey)
      belongs_to(:user, User)
    end
  end

  defmodule Definition do
    @moduledoc """
    Example Ecto definition for the modules defined above.
    """

    @behaviour Loupe.Ecto.Definition

    import Ecto.Query

    @schemas %{
      "Post" => Post,
      "User" => User,
      "Role" => Role,
      "ExternalKey" => ExternalKey,
      "UserExternalKey" => UserExternalKey,
      "Comment" => Comment
    }

    @impl Loupe.Ecto.Definition
    def schemas(%{role: "admin"}), do: @schemas
    def schemas(_), do: Map.take(@schemas, ["Post", "User", "Comment"])

    @impl Loupe.Ecto.Definition
    def schema_fields(_, %{role: "admin"}), do: :all
    def schema_fields(Post, _), do: {:only, [:title, :body, :moderator]}
    def schema_fields(User, _), do: {:only, [:email, :posts]}
    def schema_fields(_, _), do: :all

    @impl Loupe.Ecto.Definition
    def scope_schema(schema, %{ordered_by_id: true}), do: order_by(schema, :id)
    def scope_schema(schema, _), do: schema

    @impl Loupe.Ecto.Definition
    def cast_sigil('m', money_string, _) do
      money_string
      |> String.to_float()
      |> then(&(&1 * 100))
      |> ceil()
    end

    def cast_sigil(_, string, _), do: string
  end

  def run_query(query, options \\ []) do
    assigns = Keyword.get(options, :assigns, %{role: "admin"})
    variables = Keyword.get(options, :variables, %{})
    preload = Keyword.get(options, :preload, [])

    result =
      case assigns do
        nil ->
          LoupeEcto.build_query(query, Definition, %{}, variables)

        _ ->
          LoupeEcto.build_query(
            query,
            Definition,
            assigns,
            variables
          )
      end

    with {:ok, %Ecto.Query{} = ecto_query, _context} <- result do
      ecto_query
      |> Repo.all()
      |> Repo.preload(preload)
    end
  end

  def create_context(test_context) do
    assigns = Map.get(test_context, :assigns, %{role: "admin"})
    implementation = Map.get(test_context, :implementation, Definition)

    [context: Context.new(implementation, assigns)]
  end

  def with_root_schema(%{context: context} = test_context) do
    root_schema_key = Map.get(test_context, :root_schema, "User")
    %{^root_schema_key => root_schema} = Context.schemas(context)
    [_ | _] = root_schema.__schema__(:fields)
    {:ok, context} = Context.put_root_schema(context, root_schema_key)
    [context: context]
  end

  def load_schemas(_) do
    # Not 100% sure why, but `__schema__/1` needs to be called once before `function_exported?/3` works.
    Enum.each([Comment, ExternalKey, UserExternalKey, User, Role, Post], fn schema ->
      schema.__schema__(:fields)
      schema.__schema__(:associations)
    end)

    :ok
  end

  def update_assigns(%Context{} = context, assigns) do
    %Context{context | assigns: assigns}
  end

  def sigil_L(query, _) do
    {:ok, %Ast{} = ast} = Language.compile(query)

    ast
  end
end
