defmodule Base85.UnrecognizedPaddingMethod do
  @moduledoc """
  Raised at runtime when an unknown padding method is specified.
  """
  defexception [:padding, :operation]

  @doc false
  def message(%__MODULE__{padding: padding, operation: op}) do
    "unrecognized padding method #{padding} requested while #{op}"
  end

  defimpl Base85.Error do
    def as_atom(_err), do: :unrecognized_padding_method
    def as_error_tuple(err), do: {:error, as_atom(err)}
  end
end
