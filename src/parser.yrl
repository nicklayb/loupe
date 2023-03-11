Terminals
get where all positive_integer double_dot identifier dot.

Nonterminals
quantifier predicates predicate range expression binding.

Rootsymbol expression.

expression -> get quantifier identifier where predicates : {get, '$2', '$3', '$5'}.

quantifier -> all : all.
quantifier -> positive_integer : unwrap('$1').
quantifier -> range : '$1'.

range -> positive_integer double_dot positive_integer : {range, '$1', '$3'}.

predicates -> all : '$1'.

binding -> identifier dot binding : ['$1' | '$3'].
binding -> identifier : ['$1'].

Erlang code.

unwrap({_, _, Value}) -> Value.
