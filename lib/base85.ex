defmodule Base85 do
  @moduledoc """
  Implements some 85-character encodings.

  While Base64 is well known and quite functional, it is not the most
  efficient encoding for turning binary data into a stream of ASCII-friendly
  text. This module implements some Base85 encodings. As the name suggests,
  it encodes data using a numbering system with a radix of 85. This number is
  chosen because it approximates the maximum number of characters in the
  "safe" range that can be effectively used.

  While it is possible to squeeze out a few more, it doesn't actually save
  any characters. So, from an efficiency standpoint, Base85 is about as good
  as it gets. And the small number of characters you have left over, you can
  tune the generated output to avoid characters that are "dangerous" in
  certain transports.

  ## Character Sets

  Various implementations of Base85 encodings
  """
  defdelegate encode(bin, opts \\ []), to: Base85.Encode
  defdelegate encode!(bin, opts \\ []), to: Base85.Encode
  defdelegate decode(bin, opts \\ []), to: Base85.Decode
  defdelegate decode!(bin, opts \\ []), to: Base85.Decode
end
