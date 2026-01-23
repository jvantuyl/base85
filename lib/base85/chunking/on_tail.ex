defmodule Base85.Chunking.OnTail do
  @stream_start_marker __MODULE__.StartOfStream
  @stream_end_marker __MODULE__.EndOfStream

  def on_tail(input_stream, func) do
    Stream.transform(
      input_stream,
      &on_tail_init/0,
      &on_tail_reduce/2,
      &on_tail_last(&1, func),
      &on_tail_after/1
    )
  end

  def on_tail_init(), do: @stream_start_marker
  def on_tail_reduce(next, @stream_start_marker), do: {[], next}
  def on_tail_reduce(next, previous), do: {[previous], next}
  def on_tail_last(@stream_start_marker, _func), do: {[], @stream_end_marker}

  def on_tail_last(last, func) do
    last
    |> func.()
    |> case do
      {bin, _metadata} = final when is_binary(bin) ->
        {[final], @stream_end_marker}

      final when is_list(final) ->
        {Enum.map(final, fn
           {b, m} when is_binary(b) -> {b, m}
           b when is_binary(b) -> b
         end), @stream_end_marker}

      final when is_binary(final) ->
        {[final], @stream_end_marker}

      _ ->
        {[], @stream_end_marker}
    end
  end

  def on_tail_after(_), do: nil
end
