defmodule Base85Test.Framing.PrefixTest do
  use ExUnit.Case, async: true

  import Base85Test.ChunkTools
  import Base85.Framing.Prefix

  alias Base85.MissingPrefix

  input = "abcdef"
  prefix = "<~"
  expected = "<~abcdef"

  for {input_chunks, test_idx} <- Enum.with_index(all_chunkings(input)) do
    @tag test_idx: test_idx, timeout: 5_000
    test "prefix addition (#{test_idx})" do
      result =
        unquote(input_chunks)
        |> add_prefix(unquote(prefix))
        |> Enum.to_list()
        |> IO.iodata_to_binary()

      assert result == unquote(expected)
    end
  end

  test_params = [
    {"length: prefix removal, input shorter than prefix, no match", false, "abc", "12345", "abc"},
    {"length: prefix removal, input shorter than prefix, truncated", false, "abc", "abcde",
     "abc"},
    {"length: prefix removal, input same size as prefix, no match", false, "abc", "123", "abc"},
    {"length: prefix removal, input same size as prefix, match", false, "abc", "abc", ""},
    {"length: prefix removal, longer input", false, "12345678", "abc", "12345678"},
    ["prefix removal, optional, not present", false, "12345", "abc", "12345"],
    ["prefix removal, optional, present", false, "12345", "123", "45"],
    [
      "prefix removal, required, not present",
      true,
      "12345",
      "abc",
      {MissingPrefix, ~s[encoded data was missing required prefix "abc"]}
    ],
    ["prefix removal, required, present", true, "12345", "123", "45"]
  ]

  for {name, required, input, prefix, expected} <- test_params do
    for {input_chunks, test_idx} <-
          input |> all_chunkings() |> Enum.sort(:desc) |> Enum.with_index() do
      @tag test_idx: test_idx, timeout: 5_000
      test "#{name} (#{test_idx})" do
        case unquote(expected) do
          {exc, msg} ->
            assert_raise(exc, msg, fn ->
              unquote(input_chunks)
              |> remove_prefix(unquote(prefix), required: unquote(required))
              |> Enum.to_list()
              |> IO.iodata_to_binary()
            end)

          expected when is_binary(expected) ->
            result =
              unquote(input_chunks)
              |> remove_prefix(unquote(prefix), required: unquote(required))
              |> Enum.to_list()
              |> IO.iodata_to_binary()

            assert result == expected
        end
      end
    end
  end
end
