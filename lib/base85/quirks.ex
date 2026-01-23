defmodule Base85.Quirks do
  use Memoize
  import Pipet, only: [pipet: 2]

  @type quirk() :: {:zero_hack, binary()} | {:space_hack, binary()}

  @spaces [10, 27, 53, 67, 43]
  @zeroes [0, 0, 0, 0, 0]

  @spec quirk_encoder([quirk()]) :: (Enumerable.t() -> Enumerable.t())
  def quirk_encoder(opts \\ []) do
    quirk_opts = Keyword.get(opts, :quirks)
    zero_hack = Keyword.get(quirk_opts, :zero_hack)
    space_hack = Keyword.get(quirk_opts, :space_hack)

    zero_hack =
      case zero_hack do
        true -> "z"
        false -> nil
        nil -> nil
        other when is_binary(other) and byte_size(other) == 1 -> other
      end

    space_hack =
      case space_hack do
        true -> "y"
        false -> nil
        nil -> nil
        other when is_binary(other) and byte_size(other) == 1 -> other
      end

    zero_code = calc_code(@zeroes, opts)
    space_code = calc_code(@spaces, opts)

    case {zero_hack, space_hack} do
      {nil, nil} ->
        & &1

      {_, nil} ->
        &Stream.map(&1, fn
          ^zero_code -> zero_hack
          x -> x
        end)

      {nil, _} ->
        &Stream.map(&1, fn
          ^space_code -> space_hack
          x -> x
        end)

      {_, _} ->
        &Stream.map(&1, fn
          ^zero_code -> zero_hack
          ^space_code -> space_hack
          x -> x
        end)
    end
  end

  @spec quirk_decoder([quirk()]) :: (Enumerable.t() -> Enumerable.t())
  def quirk_decoder(opts) do
    quirk_opts = Keyword.get(opts, :quirks, zero_hack: true, space_hack: true)
    zero_hack = Keyword.get(quirk_opts, :zero_hack)
    space_hack = Keyword.get(quirk_opts, :space_hack)

    zero_hack =
      case zero_hack do
        true -> "z"
        false -> nil
        nil -> nil
        other when is_binary(other) and byte_size(other) == 1 -> other
      end

    space_hack =
      case space_hack do
        true -> "y"
        false -> nil
        nil -> nil
        other when is_binary(other) and byte_size(other) == 1 -> other
      end

    zero_code = calc_code(@zeroes, opts)
    space_code = calc_code(@spaces, opts)

    &quirk_dec(&1, zero_hack, zero_code, space_hack, space_code)
  end

  defp quirk_dec(stream, zero_hack, zero_code, space_hack, space_code) do
    pipet stream do
      if zero_hack,
        do:
          Stream.transform(
            {zero_hack, zero_code},
            &quirk_dec_reduce/2
          )

      if space_hack,
        do:
          Stream.transform(
            {space_hack, space_code},
            &quirk_dec_reduce/2
          )
    end
  end

  defp quirk_dec_reduce(next, {pre, post}) do
    emit =
      next
      |> :binary.split(pre, [:global])
      |> Enum.intersperse(post)
      |> Enum.filter(fn x -> x != "" end)

    {emit, {pre, post}}
  end

  defmemo calc_code([i1, i2, i3, i4, i5], opts) do
    charset_id = Keyword.get(opts, :charset, :safe85)
    charset = Base85.Charsets.charset(charset_id)

    <<
      Enum.at(charset, i1),
      Enum.at(charset, i2),
      Enum.at(charset, i3),
      Enum.at(charset, i4),
      Enum.at(charset, i5)
    >>
  end
end
