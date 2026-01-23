defmodule Base85.Encoder do
  @moduledoc """
  Implements encoding functionality for Base85 encoding in pure Elixir.

  Supports encoding profiles: `:default`, `:ascii85`, `:zeromq`, and `:postgresql`.
  Each profile configures the appropriate charset, padding, framing, and quirks.
  """
  import Pipet
  import Base85.Charsets, only: [charset_encoder: 1]
  import Base85.Chunking, only: [rechunk: 2]
  import Base85.Framing, only: [framing_encoder: 1]
  import Base85.Padding, only: [padding_encoders: 1]
  import Base85.Quirks, only: [quirk_encoder: 1]

  @profiles %{
    default: [
      charset: :safe85,
      padding: :pkcs7,
      framing: :none,
      quirks: [space_hack: true, zero_hack: true]
    ],
    ascii85: [
      charset: :ascii85,
      padding: :ascii85,
      framing: :ascii85,
      quirks: [zero_hack: true]
    ],
    zeromq: [
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

  def encode(bin_stream, opts \\ []) do
    profile = Keyword.get(opts, :profile, :default)
    opts = Keyword.merge(@profiles[profile], opts)

    charset = charset_encoder(opts)
    quirks = quirk_encoder(opts)
    {padding_pre, padding_post} = padding_encoders(opts)
    {framing_pre, framing_post} = framing_encoder(opts)

    # could come in as chunks of any size
    pipet bin_stream do
      # currently no pre-framing needed during encoding
      framing_pre.()
      # rechunk to 4-bytes of binary data
      rechunk(4)
      # pad final short chunk
      padding_pre.()
      # translate from 4-byte unencoded binary data to 5-byte encoded text
      charset.()
      # apply quirks (special characters for common blocks)
      quirks.()
      # truncate encoded bytes if padding needs that
      padding_post.()
      # add any headers / trailers
      framing_post.()
    end
  end
end
