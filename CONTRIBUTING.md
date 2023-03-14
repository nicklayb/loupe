# Contributing

I'd be extremely happy to receive pull requests, really! But I like the code to be written in a certain and I'd like to keep it like such for this repository.

## Variables name

- **Must** but complete words, abbrevations and single letter variables are prohibited.
- **Must** be descriptive of the type and intent. Plural for lists/maps, singular for individual items.
- **Must** not include a type indicator. `value_int`, for instance, is prohibited, try and use a word that means a numeric values represented by an integer.

## Modules

- **Must** have a moduledoc.

## Public functions

- **Must** have `@doc` and `@spec`.
- Delegating work to a private function must either use another name or differenty arity, **no** `do_` prefix.
- **Must** have a reasonable number of arguments. More than around 5 arguments needs to be a Keyword list or a given structure.

## Function body

- **Must** be kept short, 10 actual statements is around the maximum length.
- **Must** have a maximum of 2 level of indentation, that means, no nested case for instance.
- **Must** pipe into a case statement. Assign to a variable and use in the case statement.
- **Must** not use `__MODULE__` for lazyness reason. Prefer aliasing the whole module name.
  - Note: `__MODULE__` could be used in the case of a macro to refer to current module.
- Macro calls **must** have parenthese except kernel macros (like `defmodule`, for instance).
- Assignations in if are prohibited (ex. `if value = function() do`)
- `nil` shouldn't be used as boolean check and should call `is_nil/1` instead.
- Dangling comments are also discouraged. Comments are only allowed when the code cannot express the explanation. Always prefer a good function/module doc instead.
- Nested calls **must** use piping instead.

