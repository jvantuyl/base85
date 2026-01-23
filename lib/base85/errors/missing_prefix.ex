defmodule Base85.MissingPrefix do
  @moduledoc """
  Raised at runtime when presented with data without a required prefix.
  """
  defexception [:prefix]

  @doc false
  def message(%__MODULE__{prefix: prefix}) do
    "encoded data was missing required prefix #{inspect(prefix)}"
  end

  defimpl Base85.Error do
    def as_atom(_err), do: :missing_prefix
    def as_error_tuple(err), do: {:error, as_atom(err)}
  end
end
