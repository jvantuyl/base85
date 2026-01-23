defmodule Base85.Framing.Whitespace do
  @moduledoc """
  Stream utility for removing whitespace from encoded data during decoding.
  """

  def remove_whitespace(stream, _opts \\ []) do
    stream
    |> Stream.flat_map(&String.split/1)
  end
end
