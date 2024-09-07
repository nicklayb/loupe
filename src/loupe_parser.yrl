Terminals
where all identifier dot boolean_operator
list_operand like comma operand string integer
negate open_paren close_paren float open_bracket close_bracket
empty sigil.

Nonterminals
quantifier predicates predicate expression binding literal list inner_list string_literal path inner_path path_part.

Rootsymbol expression.

expression -> identifier quantifier identifier where predicates : {unwrap('$1'), '$2', unwrap('$3'), '$5'}.
expression -> identifier identifier where predicates : {unwrap('$1'), {int, 1}, unwrap('$2'), '$4'}.
expression -> identifier quantifier identifier : {unwrap('$1'), '$2', unwrap('$3'), nil}.
expression -> identifier identifier : {unwrap('$1'), {int, 1}, unwrap('$2'), nil}.

quantifier -> all : all.
quantifier -> integer dot dot integer : {range, {unwrap('$1'), unwrap('$4')}}.
quantifier -> integer : {int, unwrap('$1')}.

predicates -> open_paren predicates close_paren boolean_operator predicates : {unwrap('$4'), '$2', '$5'}.
predicates -> open_paren predicates close_paren : '$2'.

predicates -> predicate boolean_operator predicates : {unwrap('$2'), '$1', '$3'}.
predicates -> predicate : '$1'.

predicate -> binding negate operand literal : {unwrap('$2'), {unwrap('$3'), {binding, '$1'}, '$4'}}.
predicate -> binding operand literal : {unwrap('$2'), {binding, '$1'}, '$3'}.

predicate -> binding negate list_operand list : {unwrap('$2'), {unwrap('$3'), {binding, '$1'}, '$4'}}.
predicate -> binding list_operand list : {unwrap('$2'), {binding, '$1'}, '$3'}.

predicate -> binding negate like string_literal : {unwrap('$2'), {unwrap('$3'), {binding, '$1'}, '$4'}}.
predicate -> binding like string_literal : {unwrap('$2'), {binding, '$1'}, '$3'}.

predicate -> binding empty : {'=', {binding, '$1'}, empty}.
predicate -> binding negate empty : {unwrap('$2'), {'=', {binding, '$1'}, empty}}.

predicate -> binding : {'=', {binding, '$1'}, true}.
predicate -> negate binding : {'=', {binding, '$2'}, false}.

binding -> identifier dot binding : [unwrap('$1') | '$3'].
binding -> identifier path : [unwrap('$1'), '$2'].
binding -> identifier : [unwrap('$1')].

literal -> string_literal : '$1'.
literal -> integer : {int, unwrap('$1')}.
literal -> float : {float, unwrap('$1')}.
literal -> sigil : {sigil, unwrap('$1')}.

string_literal -> string : {string, unwrap('$1')}.

path -> open_bracket inner_path close_bracket : {path, '$2'}.

inner_path -> path_part comma inner_path : ['$1' | '$3'].
inner_path -> path_part : ['$1'].

path_part -> string : unwrap('$1').
path_part -> identifier : unwrap('$1').

list -> open_bracket inner_list close_bracket : {list, '$2'}.

inner_list -> literal comma inner_list : ['$1' | '$3'].
inner_list -> literal : ['$1'].

Erlang code.

unwrap({_, _, Value}) -> Value.
