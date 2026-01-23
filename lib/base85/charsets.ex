defmodule Base85.Charsets do
  @moduledoc """
  Implements various character sets used for Base85 encoding.

  Available character sets:

    * `:safe85` - URL and filename safe character set (default)
    * `:ascii85` - Adobe's original ASCII85 character set
    * `:zeromq` - ZeroMQ's Z85 character set
    * `:postgresql` - PostgreSQL-safe character set that avoids SQL syntax conflicts
  """
  use Memoize

  alias Base85.InvalidCharacterForCharacterSet
  # These are charlists, since I actually want a list of chars.
  @typedoc "available character sets"
  @type charset_id :: :safe85 | :ascii85 | :zeromq | :postgresql
  @type charset :: charlist()

  @doc """
  Returns a map of character sets.
  """
  @spec charset(charset_id()) :: charlist()
  def charset(cs) do
    case cs do
      :safe85 ->
        ~c"!$()*+,-.0123456789:;=>@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz{|}~"

      :ascii85 ->
        ~c"!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstu"

      :zeromq ->
        ~c"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-:+=^!/*?&<>()[]{}@%$#"

      :postgresql ->
        ~c"!/()*+,.0123456789:;=<>@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz{|}~"

      _ ->
        raise Base85.UnrecognizedCharacterSet, charset: cs
    end
  end

  def charsets do
    [:safe85, :ascii85, :zeromq, :postgresql]
  end

  def charset_encoder(opts \\ []) do
    charset = Keyword.get(opts, :charset, :safe85)
    &encode(&1, charset(charset))
  end

  def charset_decoder(opts \\ []) do
    charset = Keyword.get(opts, :charset, :safe85)
    &decode(&1, charset(charset), charset)
  end

  def encode(bin_stream, charset) do
    i2c = &int2char(charset, &1)

    bin_stream
    |> Stream.map(&encode_chunk(&1, i2c))
  end

  def decode(char_stream, charset, charset_id) do
    c2i = &char2int(charset, valid_char(&1, charset, charset_id))

    char_stream
    |> Stream.map(&decode_chunk(&1, c2i))
  end

  def encode_chunk({chunk, metadata}, i2c) do
    {encode_chunk(chunk, i2c), metadata}
  end

  def encode_chunk(<<chunk::integer-big-size(32)>>, i2c) do
    {chun_, i1} = {div(chunk, 85), rem(chunk, 85)}
    {chu__, i2} = {div(chun_, 85), rem(chun_, 85)}
    {ch___, i3} = {div(chu__, 85), rem(chu__, 85)}
    {c____, i4} = {div(ch___, 85), rem(ch___, 85)}
    i5 = c____

    c5 = i2c.(i1)
    c4 = i2c.(i2)
    c3 = i2c.(i3)
    c2 = i2c.(i4)
    c1 = i2c.(i5)

    <<c1, c2, c3, c4, c5>>
  end

  def decode_chunk({chunk, metadata}, c2i) do
    {decode_chunk(chunk, c2i), metadata}
  end

  def decode_chunk(<<c1, c2, c3, c4, c5>>, c2i) do
    i1 = c2i.(c5)
    i2 = c2i.(c4)
    i3 = c2i.(c3)
    i4 = c2i.(c2)
    i5 = c2i.(c1)

    chunk = (((i5 * 85 + i4) * 85 + i3) * 85 + i2) * 85 + i1
    <<chunk::integer-big-size(32)>>
  end

  def decode_chunk(bad_bin, _c2i) when is_binary(bad_bin) and byte_size(bad_bin) != 5 do
    raise Base85.InvalidEncodedLength,
      hint:
        "decoding function encountered incorrectly sized chunk, #{byte_size(bad_bin)} instead of 5"
  end

  # charset helpers
  defmemo int2char(charset, int)
  defmemo int2char([char | _], 0), do: char
  defmemo int2char([_ | charset], idx), do: int2char(charset, idx - 1)
  defmemo int2char([], _), do: nil

  defmemo char2int(charset, char, idx \\ 0)
  defmemo char2int([char | _], char, idx), do: idx
  defmemo char2int([_ | charset], char, idx), do: char2int(charset, char, idx + 1)
  defmemo char2int([], _, _), do: nil

  defmemo valid_char(char, charset, charset_id) do
    if char not in charset do
      raise InvalidCharacterForCharacterSet, char: char, charset: charset_id
    end

    char
  end
end
