defmodule Base85.InvalidUnencodedLength do
  @moduledoc """
  Raised at runtime when presented with unencoded data with an invalid
  length.
  """
  defexception [:padding, :hint]

  @doc false
  def message(%__MODULE__{padding: padding, hint: hint}) do
    "raw data had invalid length for padding method #{padding}" <>
      if is_nil(hint) do
        ""
      else
        ", expected #{hint}"
      end
  end

  defimpl Base85.Error do
    def as_atom(_err), do: :invalid_unencoded_length
    def as_error_tuple(err), do: {:error, as_atom(err)}
  end
end
