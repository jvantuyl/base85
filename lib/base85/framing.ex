defmodule Base85.Framing do
  @moduledoc """
  Handles framing operations (prefixes, suffixes, whitespace) for different
  encoding formats like ASCII85.
  """

  alias Base85.Framing.{Prefix, Suffix}

  defdelegate remove_prefix(stream, prefix, opts \\ []), to: Base85.Framing.Prefix
  defdelegate remove_suffix(stream, suffix, opts \\ []), to: Base85.Framing.Suffix
  defdelegate remove_whitespace(stream, opts \\ []), to: Base85.Framing.Whitespace

  def framing_encoder(opts \\ []) do
    {framing, opts} = Keyword.pop(opts, :framing, :default)

    if framing == :ascii85 do
      {&frame_ascii85_pre(&1, opts), &frame_ascii85_post(&1, opts)}
    else
      {&frame_none_pre(&1, opts), &frame_none_post(&1, opts)}
    end
  end

  def framing_decoder(opts \\ []) do
    {framing, opts} = Keyword.pop(opts, :framing, :default)

    if framing == :ascii85 do
      {&unframe_ascii85_pre(&1, opts), &unframe_ascii85_post(&1, opts)}
    else
      {&unframe_none_pre(&1, opts), &unframe_none_post(&1, opts)}
    end
  end

  defp frame_ascii85_pre(stream, _opts) do
    stream
  end

  defp frame_ascii85_post(stream, opts) do
    stream
    |> strip_metadata()
    |> Prefix.add_prefix("<~", opts)
    |> Suffix.add_suffix("~>", opts)
  end

  defp unframe_ascii85_pre(stream, opts) do
    stream
    |> remove_whitespace(opts)
    |> Prefix.remove_prefix("<~", opts)
    |> Suffix.remove_suffix("~>", opts)
  end

  defp unframe_ascii85_post(stream, _opts) do
    stream
    |> strip_metadata()
  end

  defp frame_none_pre(stream, _opts) do
    stream
  end

  defp frame_none_post(stream, _opts) do
    stream
    |> strip_metadata()
  end

  defp unframe_none_pre(stream, _opts) do
    stream
    |> remove_whitespace()
  end

  defp unframe_none_post(stream, _opts) do
    stream
    |> strip_metadata()
  end

  defp strip_metadata(stream) do
    Stream.map(
      stream,
      fn
        {bin, _metadata} when is_binary(bin) -> bin
        bin when is_binary(bin) -> bin
      end
    )
  end
end
