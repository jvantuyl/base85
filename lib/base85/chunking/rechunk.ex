defmodule Base85.Chunking.Rechunk do
  @moduledoc """
  Stream transformer that re-chunks binary data into fixed-size segments.
  """

  def rechunk(stream, chunk_size) when is_integer(chunk_size) and chunk_size > 0 do
    Stream.transform(
      stream,
      &rechunk_init/0,
      &rechunk_reduce(&1, &2, chunk_size),
      &rechunk_last/1,
      &rechunk_after/1
    )
  end

  defp rechunk_init, do: nil

  defp rechunk_reduce(next, "", chunk_size) do
    rechunk_reduce(next, nil, chunk_size)
  end

  defp rechunk_reduce("", partial, _chunk_size) do
    {[], partial}
  end

  defp rechunk_reduce(next, partial, chunk_size) when byte_size(partial) < chunk_size do
    bytes_needed = chunk_size - byte_size(partial)

    case next do
      <<enough::binary-size(bytes_needed), rest::binary>> ->
        complete = partial <> enough
        {subsequent_chunks, remainder} = rechunk_reduce(rest, nil, chunk_size)

        {[complete | subsequent_chunks], remainder}

      incomplete ->
        {[], partial <> incomplete}
    end
  end

  defp rechunk_reduce(oversize, nil, chunk_size) when byte_size(oversize) > 4 do
    len = byte_size(oversize)
    full_chunks = div(len, chunk_size) * chunk_size

    tail_chunk =
      if len != full_chunks do
        binary_part(oversize, full_chunks, len - full_chunks)
      end

    {for(<<chunk::binary-size(chunk_size) <- oversize>>, do: chunk), tail_chunk}
  end

  defp rechunk_reduce(exact, nil, chunk_size) when byte_size(exact) == chunk_size do
    {[exact], nil}
  end

  defp rechunk_reduce(partial, nil, chunk_size) when byte_size(partial) < chunk_size do
    {[], partial}
  end

  defp rechunk_last(nil) do
    {[], nil}
  end

  defp rechunk_last(tail) do
    {[tail], nil}
  end

  defp rechunk_after(_), do: nil
end
