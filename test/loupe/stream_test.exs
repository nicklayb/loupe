defmodule Loupe.StreamTest do
  use Loupe.TestCase, async: true
  doctest Loupe.Stream

  defmodule VariantComparator do
    @behaviour Loupe.Stream.Comparator

    alias Loupe.Stream.Comparator
    alias Loupe.Stream.DefaultComparator

    @impl Comparator
    def compare(operator) do
      DefaultComparator.compare(operator)
    end

    @impl Comparator
    def apply_variant(value, "upper") do
      String.upcase(value)
    end

    def apply_variant(value, _), do: value

    @impl Comparator
    def cast_sigil(_, value), do: value
  end

  @json_data "./test/support/fixtures/issues.json"
             |> File.read!()
             |> Jason.decode!()

  describe "query/3" do
    setup [:create_stream]

    @tag query: ~s|get A where labels.name = "tech debt"|
    test "filters a map stream for one item", %{stream: stream} do
      assert [%{"labels" => [%{"name" => "tech debt"}]}] = Enum.to_list(stream)
    end

    @tag query: ~s|get all A where labels.name not :empty|
    test "filters a map stream for multiple item", %{stream: stream} do
      assert [
               %{
                 "labels" => [
                   %{"name" => "tech debt"}
                 ]
               },
               %{
                 "labels" => [
                   %{"name" => "enhancement"},
                   %{"name" => "implementation"}
                 ]
               },
               %{
                 "labels" => [
                   %{"name" => "enhancement"},
                   %{"name" => "syntax"}
                 ]
               },
               %{
                 "labels" => [
                   %{"name" => "enhancement"},
                   %{"name" => "implementation"}
                 ]
               }
             ] = Enum.to_list(stream)

      assert [
               %{
                 "labels" => [
                   %{"name" => "tech debt"}
                 ]
               },
               %{
                 "labels" => [
                   %{"name" => "enhancement"},
                   %{"name" => "implementation"}
                 ]
               }
             ] = Enum.take(stream, 2)
    end

    @tag query: ~s|get where draft|
    test "filters map with true boolean value", %{stream: stream} do
      assert [%{"number" => 26, "draft" => true}] = Enum.to_list(stream)
    end

    @tag query: ~s|get where not draft|
    test "filters map with false boolean value", %{stream: stream} do
      assert [%{"number" => 29, "draft" => false}] = Enum.to_list(stream)
    end

    @tag query: ~s|get where random_float > 5.0|
    test "filters map with float", %{stream: stream} do
      assert [%{"number" => 28, "random_float" => 8.1}] = Enum.to_list(stream)
    end

    @tag query: ~s|get where only_valid_here not :empty|
    test "filters map with a value that doesn't exist everywhere", %{stream: stream} do
      assert [%{"number" => 10, "only_valid_here" => "hello"}] = Enum.to_list(stream)
    end

    @tag query: ~s|get all where number = 17 or number = 29|
    test "filters map with or operator", %{stream: stream} do
      assert [%{"number" => 29}, %{"number" => 17}] = Enum.to_list(stream)
    end

    @tag query: ~s|get where user.login = "nicklayb" and number = 29|
    test "filters map with and operator", %{stream: stream} do
      assert [%{"number" => 29, "user" => %{"login" => "nicklayb"}}] = Enum.to_list(stream)
    end

    @tag query: ~s|get where assignee :empty|
    test "filters map with null field", %{stream: stream} do
      assert [%{"number" => 29, "assignee" => nil}] = Enum.to_list(stream)
    end

    @tag [
      comparator: VariantComparator,
      query: ~s|get where assignee:upper = "SOMETHING"|
    ]
    test "filters but ignores variant on null field", %{stream: stream} do
      assert [] = Enum.to_list(stream)
    end

    @tag [
      comparator: VariantComparator,
      query: ~s|get where labels.name:upper = "TECH DEBT"|
    ]
    test "filters with variant", %{stream: stream} do
      assert [%{"number" => 28, "labels" => [%{"name" => "tech debt"}]}] = Enum.to_list(stream)
    end

    @tag query: ~s|get A|
    test "filters nothing when no predicate", %{stream: stream} do
      assert [%{"number" => 29}] = Enum.to_list(stream)
    end

    @data [
      %{name: "Alex Lifeson", instruments: [%{name: "Guitar"}]},
      %{
        name: "Geddy Lee",
        instruments: [%{name: "Bass"}, %{name: "Synthesizer"}, %{name: "Voice"}]
      },
      %{name: "Neil Peart", instruments: [%{name: "Drums"}, %{name: "Lyrics"}]}
    ]
    @tag [
      query: ~s|get where instruments.name = "Drums"|,
      data: @data
    ]
    test "filters atom-keyed map", %{stream: stream} do
      assert [%{name: "Neil Peart"}] = Enum.to_list(stream)
    end

    @tag [
      query: ~s|get where instruments.not_valid_atom = "Drums"|,
      data: @data
    ]
    test "filters atom-keyed map fails gracefully if field can't be converted as atom", %{
      stream: stream
    } do
      assert_raise(ArgumentError, fn ->
        String.to_existing_atom("not_valid_atom")
      end)

      assert [] = Enum.to_list(stream)
    end
  end

  defp create_stream(context) do
    query = Map.fetch!(context, :query)
    comparator = Map.get(context, :comparator, Loupe.Stream.DefaultComparator)
    data = Map.get_lazy(context, :data, fn -> @json_data end)

    assert {:ok, stream} = Loupe.Stream.query(query, data, comparator: comparator)
    [stream: stream]
  end
end
