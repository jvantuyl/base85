defmodule Base85Test.ChunkTools do
  def all_chunkings(<<>>) do
    []
  end

  def all_chunkings(<<_>> = b) do
    [[b]]
  end

  def all_chunkings(<<a::binary-1, b::binary>>) do
    for [h | t] <- all_chunkings(b), reduce: [] do
      acc ->
        [[a, h | t], [a <> h | t] | acc]
    end
  end
end
