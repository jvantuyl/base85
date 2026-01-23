defmodule Base85.Chunking do
  defdelegate rechunk(stream, size), to: Base85.Chunking.Rechunk
  defdelegate on_tail(stream, func), to: Base85.Chunking.OnTail
end
