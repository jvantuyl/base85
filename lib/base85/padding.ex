defmodule Base85.Padding do
  @moduledoc """
  Implements various padding schemes for Base85 encodings.
  """

  @type padding_type() :: :none | :pkcs7

  @spec get_pad_fun(keyword() | padding_type()) :: (binary(), keyword() -> binary())
  def get_pad_fun(opts) when is_list(opts) do
    padding = Keyword.get(opts, :padding)
    get_pad_fun(padding)
  end

  def get_pad_fun(type) when is_atom(type) do
    case type do
      :none ->
        &pad_none/2

      :pkcs7 ->
        &pad_pkcs7/2

      other ->
        raise Base85.UnrecognizedPadding, padding: other, operation: :encoding
    end
  end

  @spec get_unpad_fun(keyword() | padding_type()) :: (binary(), keyword() -> binary())
  def get_unpad_fun(opts) when is_list(opts) do
    type = Keyword.get(opts, :padding)
    get_unpad_fun(type)
  end

  def get_unpad_fun(type) when is_atom(type) do
    case type do
      :none ->
        &unpad_none/2

      :pkcs7 ->
        &unpad_pkcs7/2

      other ->
        raise Base85.UnrecognizedPadding, padding: other, operation: :decoding
    end
  end

  # private functions

  defp pad_none(bin, _opts) do
    if rem(byte_size(bin), 4) != 0 do
      raise Base85.InvalidUnencodedLength, padding: :none, hint: "multiple of 4 bytes"
    end

    bin
  end

  defp unpad_none(bin, _opts) do
    bin
  end

  defp pad_pkcs7(bin, _opts) do
    bin
    |> byte_size()
    |> rem(4)
    |> case do
      0 -> <<bin::binary, 4, 4, 4, 4>>
      1 -> <<bin::binary, 3, 3, 3>>
      2 -> <<bin::binary, 2, 2>>
      3 -> <<bin::binary, 1>>
    end
  end

  defp unpad_pkcs7(bin, _opts) when byte_size(bin) > 0 do
    size = byte_size(bin)
    <<pad_bytes::integer-8>> = binary_part(bin, size - 1, 1)

    cond do
      rem(size, 4) != 0 ->
        raise Base85.InternalError, "decoding function returned incorrect length of data"

      pad_bytes not in 1..4 ->
        raise Base85.InvalidPaddingData,
          padding: :pkcs7,
          hint: "from 1 to 4 bytes, not #{pad_bytes}"

      true ->
        binary_part(bin, 0, size - pad_bytes)
    end
  end
end
