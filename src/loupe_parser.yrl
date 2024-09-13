Terminals
where all identifier dot boolean_operator
list_operand like comma operand string integer
negate open_paren close_paren float open_bracket close_bracket
empty sigil colon open_curly close_curly single_ampersand single_pipe.

Nonterminals
quantifier predicates predicate expression binding literal list 
inner_list string_literal path inner_path path_part key_value_pair 
schema key_value_pairs object composed_binding or_binding and_binding.

Rootsymbol expression.

expression -> identifier quantifier schema where predicates : {unwrap('$1'), '$2', '$3', '$5'}.
expression -> identifier schema where predicates : {unwrap('$1'), {int, 1}, '$2', '$4'}.
expression -> identifier quantifier schema : {unwrap('$1'), '$2', '$3', nil}.
expression -> identifier schema : {unwrap('$1'), {int, 1}, '$2', nil}.

schema -> identifier object : {unwrap('$1'), '$2'}.
schema -> identifier : {unwrap('$1'), nil}.

object -> open_curly key_value_pairs close_curly : {object, '$2'}.

key_value_pairs -> key_value_pair comma key_value_pairs : ['$1' | '$3'].
key_value_pairs -> key_value_pair : ['$1'].

key_value_pair -> identifier colon literal : {unwrap('$1'), '$3'}.
key_value_pair -> identifier colon object : {unwrap('$1'), '$3'}.

quantifier -> all : all.
quantifier -> integer dot dot integer : {range, {unwrap('$1'), unwrap('$4')}}.
quantifier -> integer : {int, unwrap('$1')}.

predicates -> open_paren predicates close_paren boolean_operator predicates : {unwrap('$4'), '$2', '$5'}.
predicates -> open_paren predicates close_paren : '$2'.

predicates -> predicate boolean_operator predicates : {unwrap('$2'), '$1', '$3'}.
predicates -> predicate : '$1'.

predicate -> composed_binding negate operand literal : {unwrap('$2'), {unwrap('$3'), {binding, '$1'}, '$4'}}.
predicate -> composed_binding operand literal : {unwrap('$2'), {binding, '$1'}, '$3'}.

predicate -> composed_binding negate list_operand list : {unwrap('$2'), {unwrap('$3'), {binding, '$1'}, '$4'}}.
predicate -> composed_binding list_operand list : {unwrap('$2'), {binding, '$1'}, '$3'}.

predicate -> composed_binding negate like string_literal : {unwrap('$2'), {unwrap('$3'), {binding, '$1'}, '$4'}}.
predicate -> composed_binding like string_literal : {unwrap('$2'), {binding, '$1'}, '$3'}.

predicate -> composed_binding empty : {'=', {binding, '$1'}, empty}.
predicate -> composed_binding negate empty : {unwrap('$2'), {'=', {binding, '$1'}, empty}}.

predicate -> composed_binding : {'=', {binding, '$1'}, true}.
predicate -> negate composed_binding : {'=', {binding, '$2'}, false}.

composed_binding -> binding single_pipe or_binding : {or_binding, ['$1' | '$3']}.
composed_binding -> binding single_ampersand and_binding : {and_binding, ['$1' | '$3']}.
composed_binding -> binding : '$1'.

or_binding -> binding single_pipe or_binding : ['$1' | '$3'].
or_binding -> binding : ['$1'].

and_binding -> binding single_ampersand and_binding : ['$1' | '$3'].
and_binding -> binding : ['$1'].

binding -> identifier dot binding : [unwrap('$1') | '$3'].
binding -> identifier path : [unwrap('$1'), '$2'].
binding -> identifier colon identifier : [unwrap('$1'), {variant, unwrap('$3')}].
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
