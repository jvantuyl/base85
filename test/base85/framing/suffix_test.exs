defmodule Base85Test.Framing.SuffixTest do
  use ExUnit.Case, async: true

  import Base85Test.ChunkTools
  import Base85.Framing.Suffix

  alias Base85.MissingSuffix

  input = "abcdef"
  suffix = "~>"
  expected = "abcdef~>"

  for {input_chunks, test_idx} <- Enum.with_index(all_chunkings(input)) do
    @tag test_idx: test_idx, timeout: 5_000
    test "suffix addition (#{test_idx})" do
      result =
        unquote(input_chunks)
        |> add_suffix(unquote(suffix))
        |> Enum.to_list()
        |> IO.iodata_to_binary()

      assert result == unquote(expected)
    end
  end

  test_params = [
    {"length: suffix removal, empty string", false, "", "~>", ""},
    {"length: suffix removal, input shorter", false, "a", "~>", "a"},
    {"length: suffix removal, input equal, no match", false, "ab", "~>", "ab"},
    {"length: suffix removal, input equal, match", false, "~>", "~>", ""},
    {"length: suffix removal, input longer, no match", false, "abc", "~>", "abc"},
    {"length: suffix removal, input longer,  match", false, "a~>", "~>", "a"},
    {"longer, no match", false, "abcdefgh", "~>", "abcdefgh"},
    {"longer, match", false, "abcdef~>", "~>", "abcdef"},
    {"suffix removal, optional, no match", false, "abcdef", "~>", "abcdef"},
    {"suffix removal, required, no match", true, "abcdef", "~>",
     {MissingSuffix, ~s[encoded data was missing required suffix "~>"]}},
    {"suffix removal, optional, match", false, "abcdef~>", "~>", "abcdef"},
    {"suffix removal, required, match", true, "abcdef~>", "~>", "abcdef"}
  ]

  for {name, required, input, suffix, expected} <- test_params do
    for {input_chunks, test_idx} <-
          input |> all_chunkings() |> Enum.sort(:desc) |> Enum.with_index() do
      @tag test_idx: test_idx, timeout: 5_000
      test "#{name} (#{test_idx})" do
        case unquote(expected) do
          {exc, msg} ->
            assert_raise(exc, msg, fn ->
              unquote(input_chunks)
              |> remove_suffix(unquote(suffix), required: unquote(required))
              |> Enum.to_list()
              |> IO.iodata_to_binary()
            end)

          expected when is_binary(expected) ->
            result =
              unquote(input_chunks)
              |> remove_suffix(unquote(suffix), required: unquote(required))
              |> Enum.to_list()
              |> IO.iodata_to_binary()

            assert result == expected
        end
      end
    end
  end
end
