defmodule Base85.MissingSuffix do
  @moduledoc """
  Raised at runtime when presented with data without a required suffix.
  """
  defexception [:suffix]

  @doc false
  def message(%__MODULE__{suffix: suffix}) do
    "encoded data was missing required suffix #{inspect(suffix)}"
  end

  defimpl Base85.Error do
    def as_atom(_err), do: :missing_suffix
    def as_error_tuple(err), do: {:error, as_atom(err)}
  end
end
