Terminals
get where all positive_integer identifier dot boolean_operator list_operand comma operand string integer range negate open_paren close_paren float open_bracket close_bracket.

Nonterminals
quantifier predicates predicate expression binding literal list inner_list.

Rootsymbol expression.

expression -> get quantifier identifier where predicates : {get, '$2', unwrap('$3'), '$5'}.
expression -> get identifier where predicates : {get, {int, 1}, unwrap('$2'), '$4'}.

quantifier -> all : all.
quantifier -> positive_integer : {int, unwrap('$1')}.
quantifier -> range : {range, unwrap('$1')}.

predicates -> open_paren predicates close_paren boolean_operator predicates : {unwrap('$4'), '$2', '$5'}.
predicates -> open_paren predicates close_paren : '$2'.
predicates -> predicate boolean_operator predicates : {unwrap('$2'), '$1', '$3'}.
predicates -> predicate : '$1'.

predicate -> binding negate operand literal : {unwrap('$2'), {unwrap('$3'), {binding, '$1'}, '$4'}}.
predicate -> binding operand literal : {unwrap('$2'), {binding, '$1'}, '$3'}.
predicate -> binding negate list_operand list : {unwrap('$2'), {unwrap('$3'), {binding, '$1'}, '$4'}}.
predicate -> binding list_operand list : {unwrap('$2'), {binding, '$1'}, '$3'}.

binding -> identifier dot binding : [unwrap('$1') | '$3'].
binding -> identifier : [unwrap('$1')].

literal -> string : {string, unwrap('$1')}.
literal -> integer : {int, unwrap('$1')}.
literal -> positive_integer : {int, unwrap('$1')}.
literal -> float : {float, unwrap('$1')}.

list -> open_bracket inner_list close_bracket : {list, '$2'}.

inner_list -> literal comma inner_list : ['$1' | '$3'].
inner_list -> literal : ['$1'].

Erlang code.

unwrap({_, _, Value}) -> Value.
