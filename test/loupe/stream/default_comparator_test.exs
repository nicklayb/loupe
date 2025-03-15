defmodule Loupe.Stream.DefaultComparatorTest do
  use Loupe.TestCase, async: true

  alias Loupe.Stream.DefaultComparator

  describe "compare/1" do
    test "compares with =" do
      assert DefaultComparator.compare({:=, "string", "string"})
      assert DefaultComparator.compare({:=, 1, 1})
      assert DefaultComparator.compare({:=, 1.2, 1.2})
      assert DefaultComparator.compare({:=, :atom, "atom"})
      assert DefaultComparator.compare({:=, nil, nil})
      assert DefaultComparator.compare({:=, true, true})
      assert DefaultComparator.compare({:=, false, false})

      refute DefaultComparator.compare({:=, "string", "not string"})
      refute DefaultComparator.compare({:=, 1, 2})
      refute DefaultComparator.compare({:=, 1.2, 2.1})
      refute DefaultComparator.compare({:=, :atom, "not atom"})
      refute DefaultComparator.compare({:=, nil, "not nil"})
      refute DefaultComparator.compare({:=, true, false})
      refute DefaultComparator.compare({:=, false, true})
    end

    test "compares with >=" do
      assert DefaultComparator.compare({:>=, "b", "a"})
      assert DefaultComparator.compare({:>=, "b", "b"})
      assert DefaultComparator.compare({:>=, 5, 3})
      assert DefaultComparator.compare({:>=, 5, 5})
      assert DefaultComparator.compare({:>=, 5.0, 3.1})
      assert DefaultComparator.compare({:>=, 5.0, 5.0})

      refute DefaultComparator.compare({:>=, "b", "c"})
      refute DefaultComparator.compare({:>=, 3, 5})
      refute DefaultComparator.compare({:>=, 3.0, 5.0})
    end

    test "compares with >" do
      assert DefaultComparator.compare({:>, "c", "b"})
      assert DefaultComparator.compare({:>, 5, 3})
      assert DefaultComparator.compare({:>, 5.0, 3.1})

      refute DefaultComparator.compare({:>, "b", "c"})
      refute DefaultComparator.compare({:>, "c", "c"})
      refute DefaultComparator.compare({:>, 3, 5})
      refute DefaultComparator.compare({:>, 5, 5})
      refute DefaultComparator.compare({:>, 3.0, 5.0})
      refute DefaultComparator.compare({:>, 5.0, 5.0})
    end

    test "compares with <" do
      assert DefaultComparator.compare({:<, "b", "c"})
      assert DefaultComparator.compare({:<, 3, 5})
      assert DefaultComparator.compare({:<, 3.0, 5.0})

      refute DefaultComparator.compare({:<, "c", "b"})
      refute DefaultComparator.compare({:<, "c", "c"})
      refute DefaultComparator.compare({:<, 5, 3})
      refute DefaultComparator.compare({:<, 5, 5})
      refute DefaultComparator.compare({:<, 5.0, 3.1})
      refute DefaultComparator.compare({:<, 5.0, 5.0})
    end

    test "compares with <=" do
      assert DefaultComparator.compare({:<=, "b", "c"})
      assert DefaultComparator.compare({:<=, "c", "c"})
      assert DefaultComparator.compare({:<=, 3, 5})
      assert DefaultComparator.compare({:<=, 5, 5})
      assert DefaultComparator.compare({:<=, 3.0, 5.0})
      assert DefaultComparator.compare({:<=, 5.0, 5.0})

      refute DefaultComparator.compare({:<=, "c", "b"})
      refute DefaultComparator.compare({:<=, 5, 3})
      refute DefaultComparator.compare({:<=, 5.0, 3.1})
    end

    test "compares with like" do
      assert DefaultComparator.compare({:like, "left", "left"})
      assert DefaultComparator.compare({:like, "left", "ef"})
      assert DefaultComparator.compare({:like, "left", "LEFT"})
      assert DefaultComparator.compare({:like, "LEFT", "left"})
      assert DefaultComparator.compare({:like, 2112, 2112})
      assert DefaultComparator.compare({:like, 5_211_245, 2112})
      assert DefaultComparator.compare({:like, 3.1415, 3.1415})
      assert DefaultComparator.compare({:like, 3.1415, 14})
      assert DefaultComparator.compare({:like, true, "ru"})

      refute DefaultComparator.compare({:like, "left", "right"})
      refute DefaultComparator.compare({:like, 2112, 1212})
      refute DefaultComparator.compare({:like, 3.145, 12})
      refute DefaultComparator.compare({:like, true, "false"})
    end

    test "compares with in" do
      assert DefaultComparator.compare({:in, 5, [1, 2, 5, 6]})
      assert DefaultComparator.compare({:in, "thing", ["some", "thing", "here"]})
      assert DefaultComparator.compare({:in, 5.4, [5.3, 5.4, 5.5, 5.6]})

      refute DefaultComparator.compare({:in, 5.4, []})
      refute DefaultComparator.compare({:in, 5.4, [1.3, 2.4, 4.5, 6.5]})
      refute DefaultComparator.compare({:in, 5, [1, 2, 6]})
    end
  end

  describe "apply_variant/2" do
    test "noop for variants" do
      Enum.each([1, 2.2, true, "hello", %{}], fn value ->
        assert value == DefaultComparator.apply_variant(value, "something")
      end)
    end
  end

  describe "cast_sigil/2" do
    test "noop for sigils" do
      Enum.each([1, 2.2, true, "hello", %{}], fn value ->
        random_char = [Enum.random(?a..?z)]
        assert value == DefaultComparator.cast_sigil(random_char, value)
      end)
    end
  end
end
