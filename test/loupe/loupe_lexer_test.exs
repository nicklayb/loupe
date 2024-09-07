defmodule LoupeLexerTest do
  use Loupe.TestCase

  describe "string/1" do
    test "parses comma" do
      assert {:ok, [{:comma, 1, :","}], 1} = :loupe_lexer.string(',')
    end

    test "parses all" do
      assert {:ok, [{:all, 1, :all}], 1} = :loupe_lexer.string('all')
    end

    test "parses where" do
      assert {:ok, [{:where, 1, :where}], 1} = :loupe_lexer.string('where')
    end

    test "parses empty" do
      assert {:ok, [{:empty, 1, :":empty"}], 1} = :loupe_lexer.string(':empty')
    end

    test "parses integer" do
      assert {:ok, [{:integer, 1, 0}], 1} = :loupe_lexer.string('0')
      assert {:ok, [{:integer, 1, -1}], 1} = :loupe_lexer.string('-1')
      assert {:ok, [{:integer, 1, -10}], 1} = :loupe_lexer.string('-10')
      assert {:ok, [{:integer, 1, 1}], 1} = :loupe_lexer.string('1')
      assert {:ok, [{:integer, 1, 10}], 1} = :loupe_lexer.string('10')
    end

    test "parses quantified integer" do
      assert {:ok, [{:integer, 1, 1_000}], 1} = :loupe_lexer.string('1K')
      assert {:ok, [{:integer, 1, 10_000}], 1} = :loupe_lexer.string('10K')
      assert {:ok, [{:integer, 1, 1_000}], 1} = :loupe_lexer.string('1k')
      assert {:ok, [{:integer, 1, 10_000}], 1} = :loupe_lexer.string('10k')

      assert {:ok, [{:integer, 1, 1_000_000}], 1} = :loupe_lexer.string('1m')
      assert {:ok, [{:integer, 1, 10_000_000}], 1} = :loupe_lexer.string('10m')
      assert {:ok, [{:integer, 1, 1_000_000}], 1} = :loupe_lexer.string('1M')
      assert {:ok, [{:integer, 1, 10_000_000}], 1} = :loupe_lexer.string('10M')
    end

    test "parses float" do
      assert {:ok, [{:float, 1, 1.20}], 1} = :loupe_lexer.string('1.20')
      assert {:ok, [{:float, 1, 0.10}], 1} = :loupe_lexer.string('0.10')
      assert {:ok, [{:float, 1, 0.10}], 1} = :loupe_lexer.string('0.10')
      assert {:ok, [{:float, 1, -1.20}], 1} = :loupe_lexer.string('-1.20')
      assert {:ok, [{:float, 1, -19.20}], 1} = :loupe_lexer.string('-19.20')
    end

    test "parses sigil" do
      assert {:ok, [{:sigil, 1, {'m', 'my sigil'}}], 1} = :loupe_lexer.string('~m"my sigil"')
      assert {:ok, [{:sigil, 1, {'c', 'other'}}], 1} = :loupe_lexer.string('~c"other"')
    end

    test "parses string" do
      assert {:ok, [{:string, 1, 'some string with space \\\"quotes\\\" 123 and numbers'}], 1} =
               :loupe_lexer.string('"some string with space \\\"quotes\\\" 123 and numbers"')
    end

    test "parses boolean operator" do
      assert {:ok, [{:boolean_operator, 1, :or}], 1} = :loupe_lexer.string('or')
      assert {:ok, [{:boolean_operator, 1, :and}], 1} = :loupe_lexer.string('and')
    end

    test "parses operand" do
      assert {:ok, [{:operand, 1, :>}], 1} = :loupe_lexer.string('>')
      assert {:ok, [{:operand, 1, :>=}], 1} = :loupe_lexer.string('>=')
      assert {:ok, [{:operand, 1, :<}], 1} = :loupe_lexer.string('<')
      assert {:ok, [{:operand, 1, :<=}], 1} = :loupe_lexer.string('<=')
      assert {:ok, [{:operand, 1, :=}], 1} = :loupe_lexer.string('=')
      assert {:ok, [{:operand, 1, :!=}], 1} = :loupe_lexer.string('!=')
    end

    test "parses list operand" do
      assert {:ok, [{:list_operand, 1, :in}], 1} = :loupe_lexer.string('in')
    end

    test "parses like" do
      assert {:ok, [{:like, 1, :like}], 1} = :loupe_lexer.string('like')
    end

    test "parses negate" do
      assert {:ok, [{:negate, 1, :not}], 1} = :loupe_lexer.string('not')
    end

    test "parses dot" do
      assert {:ok, [{:dot, 1, :.}], 1} = :loupe_lexer.string('.')
    end

    test "parses identifier" do
      assert {:ok, [{:identifier, 1, 'something'}], 1} = :loupe_lexer.string('something')

      assert {:ok, [{:identifier, 1, 'with_underscore'}], 1} =
               :loupe_lexer.string('with_underscore')

      assert {:ok, [{:identifier, 1, 'with_numbers_123'}], 1} =
               :loupe_lexer.string('with_numbers_123')
    end

    test "parse groupers" do
      assert {:ok, [{:open_paren, 1, :"("}], 1} = :loupe_lexer.string('(')
      assert {:ok, [{:close_paren, 1, :")"}], 1} = :loupe_lexer.string(')')
      assert {:ok, [{:open_bracket, 1, :"["}], 1} = :loupe_lexer.string('[')
      assert {:ok, [{:close_bracket, 1, :"]"}], 1} = :loupe_lexer.string(']')
    end

    test "parse path" do
      assert {:ok,
              [
                {:open_bracket, 1, :"["},
                {:string, 1, 'first'},
                {:comma, 1, :","},
                {:identifier, 1, 'second'},
                {:comma, 1, :","},
                {:string, 1, 'third'},
                {:close_bracket, 1, :"]"}
              ], 1} = :loupe_lexer.string('["first", second, "third"]')
    end

    test "parse variant" do
      assert {:ok,
              [
                {:identifier, 1, 'field'},
                {:colon, 1, :":"},
                {:identifier, 1, 'variant'}
              ], _} = :loupe_lexer.string('field:variant')
    end
  end
end
