defmodule Base85.UnrecognizedCharacterSet do
  @moduledoc """
  Raised at runtime when an unknown character set is specified.
  """
  defexception [:charset, :operation]

  @doc false
  def message(%__MODULE__{charset: charset, operation: op}) do
    "unrecognized character set #{charset} requested while #{op}"
  end
end

defmodule Base85.UnrecognizedPadding do
  @moduledoc """
  Raised at runtime when an unknown padding method is specified.
  """
  defexception [:padding, :operation]

  @doc false
  def message(%__MODULE__{padding: padding, operation: op}) do
    "unrecognized padding method #{padding} requested while #{op}"
  end
end

defmodule Base85.InvalidCharacterForCharacterSet do
  @moduledoc """
  Raised at runtime when decoding finds an invalid coding for the specified
  character set.
  """
  defexception [:character, :charset]

  @doc false
  def message(%__MODULE__{character: char, charset: charset}) do
    "invalid character value #{char} for character set #{charset}"
  end
end

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
end

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
end

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
end

defmodule Base85.InternalError do
  @moduledoc """
  Raised at runtime when an internal error is encountered.
  """
  defexception [:message]
end
