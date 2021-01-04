defmodule Base85.Decode do
  @moduledoc """
  Implements decoding functionality for Base85 encoding.
  """

  import Base85.{Charsets, Padding}

  @spec decode!(binary(), keyword()) :: binary()
  def decode!(bin, opts \\ []) when is_binary(bin) do
    dec_fun = get_dec_fun(opts)
    unpad_fun = get_unpad_fun(opts)

    if rem(byte_size(bin), 5) != 0 do
      raise Base85.InvalidEncodedLength, hint: "multiple of 5 characters"
    end

    if bin == <<>> do
      # special case for all encodings (for now)
      <<>>
    else
      bin
      |> decode_chunks(dec_fun, opts)
      |> IO.iodata_to_binary()
      |> unpad_fun.(opts)
    end
  end

  @spec decode(binary(), keyword()) :: {:ok, binary()}
  def decode(bin, opts) when is_binary(bin) do
    {:ok, decode!(bin, opts)}
  rescue
    Base85.UnrecognizedCharacterSet ->
      {:error, :unrecognized_character_set}

    Base85.UnrecognizedPadding ->
      {:error, :unrecognized_padding}

    Base85.InvalidEncodedLength ->
      {:error, :invalid_encoded_length}

    Base85.InvalidCharacterForCharacterSet ->
      {:error, :invalid_character_for_character_set}

    Base85.InvalidPaddingData ->
      {:error, :invalid_padding_data}

    Base85.InternalError ->
      {:error, :internal_error}
  end

  # private functions

  defp decode_chunks(bin, dec_fun, opts, decoded \\ [])

  defp decode_chunks(<<>>, _dec_fun, _opts, decoded) do
    Enum.reverse(decoded)
  end

  defp decode_chunks(<<d1::8, d2::8, d3::8, d4::8, d5::8, rest::binary>>, dec_fun, opts, decoded) do
    val = dec_fun.(d1)
    val = val * 85 + dec_fun.(d2)
    val = val * 85 + dec_fun.(d3)
    val = val * 85 + dec_fun.(d4)
    val = val * 85 + dec_fun.(d5)
    decode_chunks(rest, dec_fun, opts, [<<val::integer-big-unsigned-32>> | decoded])
  end

  defp get_dec_fun(opts) do
    charset = Keyword.get(opts, :charset, :safe85)

    if not Map.has_key?(charsets(), charset) do
      raise Base85.UnrecognizedCharacterSet, charset: charset, operation: :decoding
    end

    dec_map = charsets()[charset] |> Enum.with_index() |> Map.new()

    &case dec_map[&1] do
      nil ->
        raise Base85.InvalidCharacterForCharacterSet, charset: charset, character: &1

      val ->
        val
    end
  end
end
