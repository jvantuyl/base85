defmodule Base85.InvalidCharacterForCharacterSet do
  @moduledoc """
  Raised at runtime when decoding finds an invalid coding for the specified
  character set.
  """
  defexception [:char, :charset]

  @doc false
  def message(%__MODULE__{char: char, charset: charset}) do
    "invalid character value #{inspect(char)} for character set #{inspect(charset)}"
  end

  defimpl Base85.Error do
    def as_atom(_err), do: :invalid_character_for_character_set
    def as_error_tuple(err), do: {:error, as_atom(err)}
  end
end
