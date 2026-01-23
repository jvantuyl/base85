defmodule Base85.InvalidEncodedLength do
  @moduledoc """
  Raised at runtime when presented with encoded data with an invalid length.
  """
  defexception [:hint]

  def message(%__MODULE__{hint: hint}) do
    "encoded data had invalid encoded length" <>
      if is_nil(hint) do
        ""
      else
        ", expected #{hint}"
      end
  end

  defimpl Base85.Error do
    def as_atom(_err), do: :invalid_encoded_length
    def as_error_tuple(err), do: {:error, as_atom(err)}
  end
end
