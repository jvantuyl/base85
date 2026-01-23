defmodule Base85.InternalError do
  @moduledoc """
  Raised at runtime when an internal error is encountered.
  """
  # credo:disable-for-this-file Credo.Check.Consistency.ExceptionNames
  defexception [:message]

  defimpl Base85.Error do
    def as_atom(_err), do: :internal_error
    def as_error_tuple(err), do: {:error, as_atom(err)}
  end
end
