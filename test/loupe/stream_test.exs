defmodule Loupe.StreamTest do
  use Loupe.TestCase, async: true
  doctest Loupe.Stream

  @json_data "./test/support/fixtures/issues.json"
             |> File.read!()
             |> Jason.decode!()

  describe "query/3" do
    test "filters a map stream for one item" do
      assert {:ok, stream} =
               Loupe.Stream.query(~s|get A where labels.name = "tech debt"|, @json_data)

      assert [%{"labels" => [%{"name" => "tech debt"}]}] = Enum.to_list(stream)
    end

    test "filters a map stream for multiple item" do
      assert {:ok, stream} =
               Loupe.Stream.query(~s|get all A where labels.name not :empty|, @json_data)

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
               },
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
  end
end
