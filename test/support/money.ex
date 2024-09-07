defmodule Money do
  defstruct [:amount, :currency]

  def new(amount, currency) do
    %Money{amount: amount, currency: currency}
  end
end

defmodule Money.Type do
  use Ecto.Type

  def type, do: :money

  def load({amount, currency}) do
    {:ok, Money.new(amount, currency)}
  end

  def dump(%Money{} = money), do: {:ok, {money.amount, to_string(money.currency)}}
  def dump(_), do: :error

  def cast(%Money{} = money) do
    {:ok, money}
  end

  def cast({amount, currency})
      when is_integer(amount) and (is_binary(currency) or is_atom(currency)) do
    {:ok, Money.new(amount, currency)}
  end

  def cast(%{"amount" => amount, "currency" => currency})
      when is_integer(amount) and (is_binary(currency) or is_atom(currency)) do
    {:ok, Money.new(amount, currency)}
  end

  def cast(%{amount: amount, currency: currency})
      when is_integer(amount) and (is_binary(currency) or is_atom(currency)) do
    {:ok, Money.new(amount, currency)}
  end

  def cast(_), do: :error
end
