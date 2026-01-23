defmodule Base85.Framing.Prefix do
  @moduledoc """
  Stream utilities for adding and removing prefixes from encoded data
  (e.g., `<~` for ASCII85).
  """

  alias Base85.MissingPrefix

  def add_prefix(stream, prefix, _opts \\ []) do
    Stream.concat(
      [prefix],
      stream
    )
  end

  def remove_prefix(stream, prefix, opts \\ []) do
    required = Keyword.get(opts, :required, false)

    stream
    |> Stream.transform(
      &rp_init/0,
      &rp_reduce(&1, &2, prefix, byte_size(prefix), prefix, required),
      &rp_last(&1, prefix, prefix, required),
      &rp_after/1
    )
  end

  defp rp_init do
    {:detect, [], 0}
  end

  defp rp_reduce(chunk, {:detect, buf, len}, prefix, prefix_len, full_prefix, required) do
    buf = [chunk | buf]
    len = len + byte_size(chunk)

    if len < prefix_len do
      {[], {:detect, buf, len}}
    else
      buf =
        buf
        |> Enum.reverse()

      rp_compare(buf, buf, prefix, full_prefix, required)
    end
  end

  defp rp_reduce(chunk, :after, _, _, _, _) do
    {[chunk], :after}
  end

  defp rp_last({:detect, buf, _len}, _, _, false), do: {Enum.reverse(buf), :done}

  defp rp_last({:detect, _buf, _len}, _prefix, full_prefix, true) do
    raise MissingPrefix, prefix: full_prefix
  end

  defp rp_last(:after, _, _, _), do: {[], :done}

  defp rp_after(_), do: nil

  # corner case where prefix is entirely consumed
  defp rp_compare(_full_buf, buf, "", _, _) do
    {buf, :after}
  end

  # exact match, release remaining buffer
  defp rp_compare(_full_buf, [head | tail], prefix, _, _) when head == prefix do
    {tail, :after}
  end

  # length match, but no prefix match, release full buffer
  defp rp_compare(full_buf, [candidate | _buf], prefix, full_prefix, required)
       when byte_size(candidate) == byte_size(prefix) and candidate != prefix do
    if required do
      raise MissingPrefix, prefix: full_prefix
    end

    {full_buf, :after}
  end

  # shorter head, chop up prefix
  defp rp_compare(full_buf, [head | tail], prefix, full_prefix, required)
       when byte_size(head) < byte_size(prefix) do
    {prefix_chunk, prefix} = :erlang.split_binary(prefix, byte_size(head))

    if prefix_chunk == head do
      # partial match, continue
      rp_compare(full_buf, tail, prefix, full_prefix, required)
    else
      # no match, release full buffer
      if required do
        raise MissingPrefix, prefix: full_prefix
      end

      {full_buf, :after}
    end
  end

  # shorter prefix, chop up head
  defp rp_compare(full_buf, [head | tail], prefix, full_prefix, required)
       when byte_size(prefix) < byte_size(head) do
    {head_chunk, head} = :erlang.split_binary(head, byte_size(prefix))

    if head_chunk == prefix do
      # exact match, long
      {[head | tail], :after}
    else
      # no match, release full buffer
      if required do
        raise MissingPrefix, prefix: full_prefix
      end

      {full_buf, :after}
    end
  end
end
