defmodule Base85.Framing.WhitespaceTest do
  use ExUnit.Case, async: true

  import Base85Test.ChunkTools
  import Base85.Framing.Whitespace

  test_data = [
    {"empty string", "", ""},
    {"all the whitespace", "\t\n\v\f\r\s", ""},
    {"short simple sentence", "A test", "Atest"},
    {"longer simple sentence", "Try now", "Trynow"},
    {"whitespace extra inside", "2 \n  3", "23"},
    {"whitespace leading", "\t 1 m t", "1mt"},
    {"whitespace trailing", "Mr tst  ", "Mrtst"},
    {"whitespace leading and trailing", " \tLast\r\n", "Last"}
  ]

  for {name, input, expected} <- test_data do
    for {input_chunks, test_idx} <- Enum.with_index(all_chunkings(input)) do
      @tag test_idx: test_idx, timeout: 5_000
      test "#{name} (#{test_idx})" do
        result =
          unquote(input_chunks)
          |> remove_whitespace()
          |> Enum.to_list()
          |> IO.iodata_to_binary()

        assert result == unquote(expected)
      end
    end
  end
end
