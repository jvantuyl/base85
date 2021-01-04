defmodule Base85.Encode do
  @moduledoc """
  Implements encoding functionality for Base85 encoding.
  """

  # Encoding basically can't fail, so non-!-versions are trivial.

  import Base85.{Charsets, Padding}

  @spec encode!(binary(), keyword()) :: binary()
  def encode!(bin, opts \\ []) when is_binary(bin) and is_list(opts) do
    enc_fun = get_enc_fun(opts)
    pad_fun = get_pad_fun(opts)

    if bin == <<>> do
      # special case for all encodings (for now)
      <<>>
    else
      bin
      |> pad_fun.(opts)
      |> encode_chunks(enc_fun, opts)
      |> IO.iodata_to_binary()
    end
  end

  @spec encode(binary, keyword) :: {:ok, binary}
  def encode(bin, opts \\ []) when is_binary(bin) and is_list(opts) do
    {:ok, encode!(bin, opts)}
  rescue
    Base85.UnrecognizedCharacterSet ->
      {:error, :unrecognized_character_set}

    Base85.UnrecognizedPadding ->
      {:error, :unrecognized_padding}

    Base85.InvalidUnencodedLength ->
      {:error, :invalid_unencoded_length}

    Base85.InternalError ->
      {:error, :internal_error}
  end

  # private functions

  defp get_enc_fun(opts) do
    charset = Keyword.get(opts, :charset, :safe85)

    if not Map.has_key?(charsets(), charset) do
      raise Base85.UnrecognizedCharacterSet, charset: charset, operation: :encoding
    end

    enc_tup = List.to_tuple(charsets()[charset])

    &elem(enc_tup, &1)
  end

  defp encode_chunks(bin, enc_fun, opts, encoded \\ [])

  defp encode_chunks(<<>>, _enc_fun, _opts, encoded) do
    Enum.reverse(encoded)
  end

  defp encode_chunks(<<base::integer-big-unsigned-32, rest::binary>>, enc_fun, opts, encoded) do
    {e5, left} = {rem(base, 85), div(base, 85)}
    {e4, left} = {rem(left, 85), div(left, 85)}
    {e3, left} = {rem(left, 85), div(left, 85)}
    {e2, left} = {rem(left, 85), div(left, 85)}
    {e1, 0} = {rem(left, 85), div(left, 85)}

    encode_chunks(rest, enc_fun, opts, [
      enc_fun.(e5),
      enc_fun.(e4),
      enc_fun.(e3),
      enc_fun.(e2),
      enc_fun.(e1) | encoded
    ])
  end
end
