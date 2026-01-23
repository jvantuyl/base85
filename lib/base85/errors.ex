defmodule Base85.Errors do
  @moduledoc """
  Defines the `Base85.Error` protocol and lists all error types for rescue clauses.
  """

  defmacro types do
    quote do
      [
        Base85.InternalError,
        Base85.InvalidCharacterForCharacterSet,
        Base85.InvalidEncodedLength,
        Base85.InvalidPaddingData,
        Base85.InvalidUnencodedLength,
        Base85.MissingPrefix,
        Base85.MissingSuffix,
        Base85.UnrecognizedCharacterSet,
        Base85.UnrecognizedPaddingMethod
      ]
    end
  end
end

defprotocol Base85.Error do
  def as_atom(err)
  def as_error_tuple(err)
end
