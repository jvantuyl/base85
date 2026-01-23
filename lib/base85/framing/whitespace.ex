defmodule Base85.Framing.Whitespace do
  def remove_whitespace(stream, _opts \\ []) do
    stream
    |> Stream.flat_map(&String.split/1)
  end
end
