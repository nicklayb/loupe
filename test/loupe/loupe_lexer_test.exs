defmodule LoupeLexerTest do
  use Loupe.TestCase

  describe "string/1" do
    test "parses comma" do
      assert {:ok, [{:comma, 1, :","}], 1} = :loupe_lexer.string(~c|,|)
    end

    test "parses all" do
      assert {:ok, [{:all, 1, :all}], 1} = :loupe_lexer.string(~c|all|)
    end

    test "parses where" do
      assert {:ok, [{:where, 1, :where}], 1} = :loupe_lexer.string(~c|where|)
    end

    test "parses empty" do
      assert {:ok, [{:empty, 1, :":empty"}], 1} = :loupe_lexer.string(~c|:empty|)
    end

    test "parses integer" do
      assert {:ok, [{:integer, 1, 0}], 1} = :loupe_lexer.string(~c|0|)
      assert {:ok, [{:integer, 1, -1}], 1} = :loupe_lexer.string(~c|-1|)
      assert {:ok, [{:integer, 1, -10}], 1} = :loupe_lexer.string(~c|-10|)
      assert {:ok, [{:integer, 1, 1}], 1} = :loupe_lexer.string(~c|1|)
      assert {:ok, [{:integer, 1, 10}], 1} = :loupe_lexer.string(~c|10|)
    end

    test "parses quantified integer" do
      assert {:ok, [{:integer, 1, 1_000}], 1} = :loupe_lexer.string(~c|1K|)
      assert {:ok, [{:integer, 1, 10_000}], 1} = :loupe_lexer.string(~c|10K|)
      assert {:ok, [{:integer, 1, 1_000}], 1} = :loupe_lexer.string(~c|1k|)
      assert {:ok, [{:integer, 1, 10_000}], 1} = :loupe_lexer.string(~c|10k|)

      assert {:ok, [{:integer, 1, 1_000_000}], 1} = :loupe_lexer.string(~c|1m|)
      assert {:ok, [{:integer, 1, 10_000_000}], 1} = :loupe_lexer.string(~c|10m|)
      assert {:ok, [{:integer, 1, 1_000_000}], 1} = :loupe_lexer.string(~c|1M|)
      assert {:ok, [{:integer, 1, 10_000_000}], 1} = :loupe_lexer.string(~c|10M|)
    end

    test "parses float" do
      assert {:ok, [{:float, 1, 1.20}], 1} = :loupe_lexer.string(~c|1.20|)
      assert {:ok, [{:float, 1, 0.10}], 1} = :loupe_lexer.string(~c|0.10|)
      assert {:ok, [{:float, 1, 0.10}], 1} = :loupe_lexer.string(~c|0.10|)
      assert {:ok, [{:float, 1, -1.20}], 1} = :loupe_lexer.string(~c|-1.20|)
      assert {:ok, [{:float, 1, -19.20}], 1} = :loupe_lexer.string(~c|-19.20|)
    end

    test "parses sigil" do
      assert {:ok, [{:sigil, 1, {~c"m", ~c"my sigil"}}], 1} =
               :loupe_lexer.string(~c|~m"my sigil"|)

      assert {:ok, [{:sigil, 1, {~c"c", ~c"other"}}], 1} = :loupe_lexer.string(~c|~c"other"|)
    end

    test "parses string" do
      assert {:ok, [{:string, 1, ~c|some string with space \\\"quotes\\\" 123 and numbers|}], 1} =
               :loupe_lexer.string(~c|"some string with space \\\"quotes\\\" 123 and numbers"|)
    end

    test "parses boolean operator" do
      assert {:ok, [{:boolean_operator, 1, :or}], 1} = :loupe_lexer.string(~c|or|)
      assert {:ok, [{:boolean_operator, 1, :and}], 1} = :loupe_lexer.string(~c|and|)
    end

    test "parses operand" do
      assert {:ok, [{:operand, 1, :>}], 1} = :loupe_lexer.string(~c|>|)
      assert {:ok, [{:operand, 1, :>=}], 1} = :loupe_lexer.string(~c|>=|)
      assert {:ok, [{:operand, 1, :<}], 1} = :loupe_lexer.string(~c|<|)
      assert {:ok, [{:operand, 1, :<=}], 1} = :loupe_lexer.string(~c|<=|)
      assert {:ok, [{:operand, 1, :=}], 1} = :loupe_lexer.string(~c|=|)
      assert {:ok, [{:operand, 1, :!=}], 1} = :loupe_lexer.string(~c|!=|)
    end

    test "parses list operand" do
      assert {:ok, [{:list_operand, 1, :in}], 1} = :loupe_lexer.string(~c|in|)
    end

    test "parses like" do
      assert {:ok, [{:like, 1, :like}], 1} = :loupe_lexer.string(~c|like|)
    end

    test "parses negate" do
      assert {:ok, [{:negate, 1, :not}], 1} = :loupe_lexer.string(~c|not|)
    end

    test "parses dot" do
      assert {:ok, [{:dot, 1, :.}], 1} = :loupe_lexer.string(~c|.|)
    end

    test "parses identifier" do
      assert {:ok, [{:identifier, 1, ~c"something"}], 1} = :loupe_lexer.string(~c|something|)

      assert {:ok, [{:identifier, 1, ~c"with_underscore"}], 1} =
               :loupe_lexer.string(~c|with_underscore|)

      assert {:ok, [{:identifier, 1, ~c"with_numbers_123"}], 1} =
               :loupe_lexer.string(~c|with_numbers_123|)
    end

    test "parse groupers" do
      assert {:ok, [{:open_paren, 1, :"("}], 1} = :loupe_lexer.string(~c|(|)
      assert {:ok, [{:close_paren, 1, :")"}], 1} = :loupe_lexer.string(~c|)|)
      assert {:ok, [{:open_bracket, 1, :"["}], 1} = :loupe_lexer.string(~c|[|)
      assert {:ok, [{:close_bracket, 1, :"]"}], 1} = :loupe_lexer.string(~c|]|)
    end

    test "parse path" do
      assert {:ok,
              [
                {:open_bracket, 1, :"["},
                {:string, 1, ~c"first"},
                {:comma, 1, :","},
                {:identifier, 1, ~c"second"},
                {:comma, 1, :","},
                {:string, 1, ~c"third"},
                {:close_bracket, 1, :"]"}
              ], 1} = :loupe_lexer.string(~c|["first", second, "third"]|)
    end

    test "parse variant" do
      assert {:ok,
              [
                {:identifier, 1, ~c"field"},
                {:colon, 1, :":"},
                {:identifier, 1, ~c"variant"}
              ], _} = :loupe_lexer.string(~c|field:variant|)
    end

    test "parse object" do
      assert {:ok,
              [
                {:open_curly, 1, :"{"},
                #
                {:identifier, 1, ~c"key"},
                {:colon, 1, :":"},
                {:string, 1, ~c"value"},
                {:comma, 1, :","},
                #
                {:identifier, 1, ~c"int"},
                {:colon, 1, :":"},
                {:integer, 1, 1},
                {:comma, 1, :","},
                #
                {:identifier, 1, ~c"float"},
                {:colon, 1, :":"},
                {:float, 1, 2.3},
                {:comma, 1, :","},
                #
                {:identifier, 1, ~c"object"},
                {:colon, 1, :":"},
                {:open_curly, 1, :"{"},
                #
                {:identifier, 1, ~c"sigil"},
                {:colon, 1, :":"},
                {:sigil, 1, {~c"m", ~c"sigil"}},
                {:comma, 1, :","},
                #
                {:identifier, 1, ~c"list"},
                {:colon, 1, :":"},
                {:open_bracket, 1, :"["},
                {:integer, 1, 1},
                {:comma, 1, :","},
                {:integer, 1, 2},
                {:comma, 1, :","},
                {:integer, 1, 3},
                {:close_bracket, 1, :"]"},
                {:close_curly, 1, :"}"},
                {:close_curly, 1, :"}"}
              ], _} =
               :loupe_lexer.string(
                 ~c|{key: "value", int: 1, float: 2.3, object: {sigil: ~m"sigil", list: [1, 2, 3]}}|
               )
    end
  end
end
