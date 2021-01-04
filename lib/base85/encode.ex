defmodule Base85.Encode do
  @moduledoc """
  Implements encoding functionality for Base85 encoding.
  """

  # Encoding basically can't fail, so non-!-versions are trivial.

  import Base85.{Charsets, Padding}

  @typedoc "available character sets"
  @type charset() :: Base85.Charsets.charset()
  @typedoc "available padding techniques"
  @type padding() :: Base85.Padding.padding()
  @typedoc "options for encoding"
  @type encoding_opts() :: [charset: charset(), padding: padding()]
  @typedoc "encoding errors"
  @type encoding_error() ::
          :unrecognized_character_set
          | :unrecognized_padding
          | :invalid_unencoded_length
          | :internal_error

  @doc """
  Encodes binary data into a Base85-encoded string.

  This version returns the value or raises an error.

  ## Examples

      iex> Base85.Encode.encode!("some binary data", charset: :safe85, padding: :pkcs7)
      "N.Xx21Kf++HD3`AI>AZp$Aer7"

      iex> Base85.Encode.encode!("123412341234", charset: :zeromq, padding: :none)
      "f!$Kwf!$Kwf!$Kw"

      iex> Base85.Encode.encode!("123", charset: :safe85, padding: :none)
      ** (Base85.InvalidUnencodedLength) raw data had invalid length for padding method none, expected multiple of 4 bytes

  ## Options

    * `binary` - the binary data to encode, must be a multiple of 32-bits long
      if no padding is used;

    * `:charset` - an atom indicating the character set to use for encoding;

    * `:padding` - an atom indicating which padding technique to use;

    Padding methods and encodings may use additional options.
  """
  @spec encode!(binary(), encoding_opts()) :: binary()
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

  @doc """
  Encodes binary data into a Base85-encoded string.

  This version returns an `:ok`-tuple or `:error`-tuple.

  ## Examples

      iex> Base85.Encode.encode("some binary data", charset: :safe85, padding: :pkcs7)
      {:ok, "N.Xx21Kf++HD3`AI>AZp$Aer7"}

      iex> Base85.Encode.encode("123412341234", charset: :zeromq, padding: :none)
      {:ok, "f!$Kwf!$Kwf!$Kw"}

      iex> Base85.Encode.encode("123", charset: :safe85, padding: :none)
      {:error, :invalid_unencoded_length}

  ## Options

    * `binary` - the binary data to encode, must be a multiple of 32-bits long
      if no padding is used;

    * `:charset` - an atom indicating the character set to use for encoding;

    * `:padding` - an atom indicating which padding technique to use;

    Padding methods and encodings may use additional options.
  """
  @spec encode(binary, encoding_opts()) :: {:ok, binary} | {:error, encoding_error()}
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
