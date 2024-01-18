Definitions.

Whitespace = [\s\t]
Terminator = \n|\r\n|\r
Comma = ,

Digit = [0-9]
NonZeroDigit = [1-9]
NegativeSign = [\-]
Sign = [\+\-]
FractionalPart = \.{Digit}+
True = true
False = false
OpenParen = \(
CloseParen = \)
OpenBracket = \[
CloseBracket = \]
Arrow = \=>
String = "([^"\\]*(\\.[^"\\]*)*)"
Quantifier = [kmKM]
BoolOp = and|or
Operand = !=|>|<|>=|<=|=
ListOperand = in
LikeOperand = like
Not = not
Dot = \.
All = all
Get = get
Where = where
As = as
Empty = :empty

Identifier  = [A-Za-z][A-Za-z0-9_]*
PositiveInt = {NonZeroDigit}|{NonZeroDigit}?{Digit}+
IntegerPart = {NegativeSign}?{PositiveInt}
IntValue    = {IntegerPart}
IntQuant    = {IntegerPart}{Quantifier}
FloatValue  = {IntegerPart}{FractionalPart}|{IntegerPart}{ExponentPart}|{IntegerPart}{FractionalPart}{ExponentPart}
DoubleDot   = {Dot}{Dot}
Range       = {PositiveInt}{DoubleDot}{PositiveInt}

Rules.

{Whitespace}    : skip_token.
{Terminator}    : skip_token.
{Comma}         : {token, {comma,             TokenLine, list_to_atom(TokenChars)}}.
{Dot}           : {token, {dot,               TokenLine, list_to_atom(TokenChars)}}.
{DoubleDot}     : {token, {double_dot,        TokenLine, list_to_atom(TokenChars)}}.
{All}           : {token, {all,               TokenLine, list_to_atom(TokenChars)}}.
{As}            : {token, {as,                TokenLine, list_to_atom(TokenChars)}}.
{Where}         : {token, {where,             TokenLine, list_to_atom(TokenChars)}}.
{Empty}         : {token, {empty,             TokenLine, list_to_atom(TokenChars)}}.
{PositiveInt}   : {token, {positive_integer,  TokenLine, list_to_integer(TokenChars)}}.
{IntValue}      : {token, {integer,           TokenLine, list_to_integer(TokenChars)}}.
{IntQuant}      : {token, {integer,           TokenLine, quantify_integer(TokenChars)}}.
{FloatValue}    : {token, {float,             TokenLine, list_to_float(TokenChars)}}.
{String}        : {token, {string,            TokenLine, string:trim(TokenChars, both, "\"")}}.
{Range}         : {token, {range,             TokenLine, extract_range(TokenChars)}}.
{BoolOp}        : {token, {boolean_operator,  TokenLine, list_to_atom(TokenChars)}}.
{Operand}       : {token, {operand,           TokenLine, list_to_atom(TokenChars)}}.
{ListOperand}   : {token, {list_operand,      TokenLine, list_to_atom(TokenChars)}}.
{LikeOperand}   : {token, {like,              TokenLine, list_to_atom(TokenChars)}}.
{Not}           : {token, {negate,            TokenLine, list_to_atom(TokenChars)}}.
{Identifier}    : {token, {identifier,        TokenLine, TokenChars}}.
{OpenParen}     : {token, {open_paren,        TokenLine, list_to_atom(TokenChars)}}.
{CloseParen}    : {token, {close_paren,       TokenLine, list_to_atom(TokenChars)}}.
{OpenBracket}   : {token, {open_bracket,      TokenLine, list_to_atom(TokenChars)}}.
{CloseBracket}  : {token, {close_bracket,     TokenLine, list_to_atom(TokenChars)}}.

Erlang code.

quantify_integer(Chars) ->
  {match, [Number, Quantifier]} = re:run(string:uppercase(Chars), "([0-9]+)([KM])",[{capture,all_but_first,list}]),
  {Value, _} = string:to_integer(Number),
  case Quantifier of
    "K" ->
      Value * 1000;

    "M" ->
      Value * 1000000
  end.

extract_range(Chars) ->
    [Minimum, Maximum] = string:split(Chars, ".."),
    {MinimumInt, _} = string:to_integer(Minimum),
    {MaximumInt, _} = string:to_integer(Maximum),
    {MinimumInt, MaximumInt}.

