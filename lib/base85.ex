defmodule Base85 do
  @moduledoc """
  A pure-Elixir implementation of some 85-character encodings.

  While Base64 is well known and quite functional, it is not the most
  efficient encoding for turning binary data into a stream of ASCII-friendly
  text. This module implements some Base85 encodings in pure Elixir, with no
  NIF or external dependencies. As the name suggests, it encodes data using
  a numbering system with a radix of 85. This number is chosen because it
  approximates the maximum number of characters in the "safe" range that can
  be effectively used.

  While it is possible to squeeze out a few more, it doesn't actually save
  any characters. So, from an efficiency standpoint, Base85 is about as good
  as it gets. And the small number of characters you have left over, you can
  tune the generated output to avoid characters that are "dangerous" in
  certain transports.

  By default, encoding uses the Safe85 character set with PKCS7 padding,
  which allows arbitrary-length input to round-trip correctly.

  This module holds references to the primary entrypoints for using this
  library.
  """

  require Base85.Errors

  @spec encode!(data :: binary, keyword()) :: binary()
  def encode!(data, opts \\ []) when is_list(opts) do
    [data]
    |> Base85.Encoder.encode(opts)
    |> Enum.to_list()
    |> IO.iodata_to_binary()
  end

  @spec decode!(data :: binary, keyword()) :: binary()
  def decode!(data, opts \\ []) when is_list(opts) do
    [data]
    |> Base85.Decoder.decode(opts)
    |> Enum.to_list()
    |> IO.iodata_to_binary()
  end

  @spec encode(data :: binary, keyword()) :: {:ok, binary()} | {:error, any()}
  def encode(data, opts \\ []) when is_list(opts) do
    encode!(data, opts)
  rescue
    error in Base85.Errors.types() -> Base85.Error.as_error_tuple(error)
  end

  @spec decode(data :: binary, keyword()) :: {:ok, binary()} | {:error, any()}
  def decode(data, opts \\ []) when is_list(opts) do
    decode!(data, opts)
  rescue
    error in Base85.Errors.types() -> Base85.Error.as_error_tuple(error)
  end

  @spec encode_stream!(stream :: Enumerable.t(binary()), keyword()) :: Enumerable.t(binary())
  def encode_stream!(stream, opts \\ []) when is_list(opts) do
    if stream |> Enumerable.impl_for() |> is_nil() do
      raise ArgumentError, "Invalid stream (must be Enumerable)"
    end

    stream
    |> Base85.Encoder.encode(opts)
  end

  @spec decode_stream!(stream :: Enumerable.t(binary()), keyword()) :: Enumerable.t(binary())
  def decode_stream!(stream, opts \\ []) when is_list(opts) do
    if stream |> Enumerable.impl_for() |> is_nil() do
      raise ArgumentError, "Invalid stream (must be Enumerable)"
    end

    stream
    |> Base85.Decoder.decode(opts)
  end

  @spec encode_stream(stream :: Enumerable.t(binary()), keyword()) ::
          {:ok, Enumerable.t(binary())} | {:error, any()}
  def encode_stream(stream, opts \\ []) when is_list(opts) do
    encode_stream!(stream, opts)
  rescue
    error in Base85.Errors.types() -> Base85.Error.as_error_tuple(error)
  end

  @spec decode_stream(stream :: Enumerable.t(binary()), keyword()) ::
          {:ok, Enumerable.t(binary())} | {:error, any()}
  def decode_stream(stream, opts \\ []) when is_list(opts) do
    decode_stream!(stream, opts)
  rescue
    error in Base85.Errors.types() -> Base85.Error.as_error_tuple(error)
  end

  defdelegate charsets(), to: Base85.Charsets
  defdelegate charset(charset_id), to: Base85.Charsets
end
