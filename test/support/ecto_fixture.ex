defmodule Loupe.Test.Ecto do
  @moduledoc "Mock schemas and Ecto modules for tests"

  defmodule Repo do
    @moduledoc "Mocked repo"

    use Ecto.Repo,
      otp_app: :loupe,
      adapter: Ecto.Adapters.SQLite3
  end

  defmodule Comment do
    @moduledoc "Comment schema"
    use Ecto.Schema

    schema("comments") do
      field(:text, :string)
      field(:post_id, :integer)
    end
  end

  defmodule Post do
    @moduledoc "Post schema"
    use Ecto.Schema

    schema("posts") do
      field(:title, :string)
      field(:body, :string)
      field(:user_id, :integer)

      has_many(:comments, Comment)
    end
  end

  defmodule Role do
    @moduledoc "Post schema"
    use Ecto.Schema

    schema("roles") do
      field(:slug, :string)
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

      has_many(:posts, Post)

      belongs_to(:role, Role)
    end
  end

  defmodule Definition do
    @moduledoc """
    Example Ecto definition for the modules defined above.
    """
    @behaviour Loupe.Ecto.Definition

    @schemas %{
      "Post" => Post,
      "User" => User,
      "Role" => Role
    }

    @impl Loupe.Ecto.Definition
    def schemas(%{role: "admin"}), do: @schemas
    def schemas(_), do: Map.take(@schemas, ["Post", "User"])

    @impl Loupe.Ecto.Definition
    def schema_fields(_, %{role: "admin"}), do: :all
    def schema_fields(Post, _), do: {:only, [:title, :body]}
    def schema_fields(User, _), do: {:only, [:email, :posts]}
    def schema_fields(_, _), do: :all

    @impl Loupe.Ecto.Definition
    def scope_schema(schema, _), do: schema
  end
end
