defmodule Loupe.Helpers do
  def walk_and_accumulate(function, accumulate, accumulator) do
    case function.() do
      {:accumulate, return, content} ->
        {return, accumulate.(content, accumulator)}

      return_value ->
        {return_value, accumulator}
    end
  end
end
