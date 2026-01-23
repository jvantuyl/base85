defmodule Base85.InvalidPaddingData do
  @moduledoc """
  Raised at runtime when presented with data with corrupted padding data.
  """
  defexception [:padding, :hint]

  @doc false
  def message(%__MODULE__{padding: padding, hint: hint}) do
    "encoded data had invalid padding bytes for padding method #{padding}" <>
      if is_nil(hint) do
        ""
      else
        ", expected #{hint}"
      end
  end

  defimpl Base85.Error do
    def as_atom(_err), do: :invalid_padding_data
    def as_error_tuple(err), do: {:error, as_atom(err)}
  end
end
