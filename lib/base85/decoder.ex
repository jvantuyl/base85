defmodule Base85.Decoder do
  @moduledoc """
  Implements decoding functionality for Base85 encoding in pure Elixir.
  """
  import Pipet
  import Base85.Charsets, only: [charset_decoder: 1]
  import Base85.Chunking, only: [rechunk: 2]
  import Base85.Framing, only: [framing_decoder: 1]
  import Base85.Padding, only: [padding_decoders: 1]
  import Base85.Quirks, only: [quirk_decoder: 1]

  @profiles %{
    default: [
      charset: :safe85,
      padding: :pkcs7,
      framing: :none,
      quirks: [:space_hack, :zero_hack]
    ],
    ascii85: [
      charset: :ascii85,
      padding: :ascii85,
      framing: :ascii85,
      quirks: [zero_hack: true]
    ],
    z85: [
      charset: :zeromq,
      padding: :none,
      framing: :none,
      quirks: []
    ],
    postgresql: [
      charset: :safe85,
      padding: :pkcs7,
      framing: :none,
      quirks: [space_hack: true, zero_hack: true]
    ]
  }

  def decode(bin_stream, opts \\ []) do
    profile = Keyword.get(opts, :profile, :default)
    opts = Keyword.merge(@profiles[profile], opts)

    charset = charset_decoder(opts)
    quirks = quirk_decoder(opts)
    {padding_pre, padding_post} = padding_decoders(opts)
    {framing_pre, framing_post} = framing_decoder(opts)

    # could come in as chunks of any size
    pipet bin_stream do
      # remove whitespace, strip headers / trailers
      framing_pre.()
      # rechunk to 5-byte encoded text chunks
      rechunk(5)
      # pad final short chunk
      padding_pre.()
      # reverse quirks (special characters for common blocks)
      quirks.()
      # translate from 5-byte encoded text to 4-byte unencoded binary data
      charset.()
      # truncate decoded bytes if padding needs that
      padding_post.()
      # currently no post-decoding framing implemented
      framing_post.()
    end
  end
end
