defmodule Base85.Padding do
  @moduledoc """
  Implements various padding schemes for Base85 encodings.

  Supported padding methods:

    * `:none` - no padding; input must be a multiple of 4 bytes
    * `:pkcs7` - PKCS7-style padding that allows arbitrary-length input
    * `:ascii85` - Adobe ASCII85 padding that encodes length in the output size
  """
  import Base85.Chunking, only: [on_tail: 2]

  @typedoc "padding methods"
  @type padding() :: :none | :pkcs7 | :ascii85

  @type transcoder :: (Enumerable.t(binary()) -> Enumerable.t(binary()))

  @doc false
  @spec padding_encoders(keyword()) :: {transcoder(), transcoder()}
  def padding_encoders(opts \\ []) do
    type = Keyword.get(opts, :padding, :pkcs7)

    {pre, post} =
      case type do
        :none ->
          {&pad_none(&1, opts), & &1}

        :pkcs7 ->
          {&pad_pkcs7(&1, opts), & &1}

        :ascii85 ->
          {&pad_ascii85_pre(&1, opts), &pad_ascii85_post(&1, opts)}

        other ->
          raise Base85.UnrecognizedPaddingMethod, padding: other, operation: :encoding
      end

    {&on_tail(&1, pre), &on_tail(&1, post)}
  end

  @doc """
  Used to get an unpadding function for a given padding type.
  """
  @spec padding_decoders(keyword()) :: {transcoder(), transcoder()}
  def padding_decoders(opts \\ []) when is_list(opts) do
    {padding, opts} = Keyword.pop(opts, :padding, :pkcs7)

    {pre, post} =
      case padding do
        :none ->
          {&unpad_none(&1, opts), & &1}

        :pkcs7 ->
          {& &1, &unpad_pkcs7(&1, opts)}

        :ascii85 ->
          {&unpad_ascii85_pre(&1, opts), &unpad_ascii85_post(&1, opts)}

        other ->
          raise Base85.UnrecognizedPaddingMethod, padding: other, operation: :decoding
      end

    {&on_tail(&1, pre), &on_tail(&1, post)}
  end

  # private functions
  defp pad_none(bin, _opts) do
    if rem(byte_size(bin), 4) != 0 do
      raise Base85.InvalidUnencodedLength, padding: :none, hint: "multiple of 4 bytes"
    end

    {bin, nil}
  end

  defp unpad_none(bin, _opts) do
    bin
  end

  defp pad_pkcs7(bin, _opts) do
    bin
    |> byte_size()
    |> rem(4)
    |> case do
      0 -> [bin, <<4, 4, 4, 4>>]
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
        raise Base85.InvalidPaddingData,
          padding: :pkcs7,
          hint: "decoding function returned incorrect length of data"

      pad_bytes not in 1..4 ->
        raise Base85.InvalidPaddingData,
          padding: :pkcs7,
          hint: "from 1 to 4 bytes, not #{pad_bytes}"

      true ->
        binary_part(bin, 0, size - pad_bytes)
    end
  end

  defp pad_ascii85_pre(bin, _opts) do
    remainder = rem(byte_size(bin), 4)

    pad_count =
      case remainder do
        0 ->
          0

        n when n in 1..3 ->
          4 - n

        n ->
          raise Base85.InvalidEncodedLength,
            padding: :ascii85,
            hint: "from 0 to 3 bytes, not #{n}"
      end

    if pad_count > 0 do
      {<<bin::binary, 0::size(pad_count * 8)>>, pad_count}
    else
      bin
    end
  end

  defp pad_ascii85_post({bin, pad_count}, _opts) when pad_count > 0 and pad_count < 5 do
    binary_slice(bin, 0, byte_size(bin) - pad_count)
  end

  defp pad_ascii85_post(bin, _opts) do
    bin
  end

  defp unpad_ascii85_pre(bin, opts) do
    remainder = rem(byte_size(bin), 5)

    pad_count =
      case remainder do
        0 ->
          0

        n when n in 2..4 ->
          5 - n

        n ->
          raise Base85.InvalidEncodedLength,
            hint: "from 2 to 4 bytes, not #{n}"
      end

    if pad_count > 0 do
      pad_char =
        Keyword.get(opts, :charset, :safe85) |> Base85.Charsets.charset() |> :lists.last()

      pad_bin = String.duplicate(<<pad_char>>, pad_count)

      {<<bin::binary, pad_bin::binary>>, pad_count}
    else
      bin
    end
  end

  defp unpad_ascii85_post({bin, pad_count}, _opts) when pad_count > 0 and pad_count < 5 do
    binary_slice(bin, 0, byte_size(bin) - pad_count)
  end

  defp unpad_ascii85_post(bin, _opts) do
    bin
  end
end
