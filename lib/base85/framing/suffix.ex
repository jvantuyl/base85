defmodule Base85.Framing.Suffix do
  @moduledoc """
  Stream utilities for adding and removing suffixes from encoded data
  (e.g., `~>` for ASCII85).
  """

  alias Base85.MissingSuffix

  def add_suffix(stream, suffix, _opts \\ []) do
    Stream.concat(
      stream,
      [suffix]
    )
  end

  def remove_suffix(stream, suffix, opts \\ []) do
    required = Keyword.get(opts, :required, false)

    stream
    |> Stream.transform(
      &rs_init/0,
      &rs_reduce(&1, &2, byte_size(suffix)),
      &rs_last(&1, suffix, required),
      &rs_after/1
    )
  end

  defp rs_init do
    {[], 0}
  end

  defp rs_reduce(next, {buf, size}, suffix_len) do
    next_size = byte_size(next)
    buf = [{next, next_size} | buf]
    size = size + next_size

    if size >= suffix_len do
      rs_release([], Enum.reverse(buf), size - suffix_len)
    else
      {[], {buf, size}}
    end
  end

  defp rs_release(released, [{head, size} | tail] = buf, remaining) do
    if remaining < size do
      rs_retain(Enum.reverse(released), [], buf, 0)
    else
      rs_release([head | released], tail, remaining - size)
    end
  end

  def rs_retain(released, retained, [{head, size} | buf], remaining) do
    rs_retain(released, [{head, size} | retained], buf, remaining + size)
  end

  def rs_retain(released, retained, [], remaining) do
    {released, {retained, remaining}}
  end

  defp rs_last({buf, _size}, suffix, required) do
    final =
      buf
      |> rs_last_join([])
      |> IO.iodata_to_binary()

    trimmed = final |> String.trim_trailing(suffix)

    if required and byte_size(trimmed) == byte_size(final) do
      raise MissingSuffix, suffix: suffix
    end

    {[trimmed], nil}
  end

  defp rs_last_join([], rest) do
    rest
  end

  defp rs_last_join([{head, _size} | tail], rest) do
    rs_last_join(tail, [head | rest])
  end

  defp rs_after(_) do
    nil
  end
end
