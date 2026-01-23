defmodule Base85.UnrecognizedCharacterSet do
  @moduledoc """
  Raised at runtime when an unknown character set is specified.
  """
  defexception [:charset, :operation]

  @doc false
  def message(%__MODULE__{charset: charset, operation: op}) do
    "unrecognized character set #{charset} requested while #{op}"
  end

  defimpl Base85.Error do
    def as_atom(_err), do: :unrecognized_character_set
    def as_error_tuple(err), do: {:error, as_atom(err)}
  end
end
