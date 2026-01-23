defmodule Base85.Chunking do
  @moduledoc """
  Facade module for stream chunking utilities used internally during encoding/decoding.
  """

  defdelegate rechunk(stream, size), to: Base85.Chunking.Rechunk
  defdelegate on_tail(stream, func), to: Base85.Chunking.OnTail
end
