defmodule Base85.CharsetsTest do
  use ExUnit.Case, async: true

  for charset_id <- Base85.Charsets.charsets(),
      charset = Base85.Charsets.charset(charset_id) do
    test "charset: length (#{charset_id})" do
      assert length(unquote(charset)) == 85
    end

    for char <- charset do
      test "charset: round-trip #{charset_id} charset, character (#{<<char>>})" do
        char_in = unquote(char)
        int = Base85.Charsets.char2int(unquote(charset), char_in)
        assert not is_nil(int)
        char_out = Base85.Charsets.int2char(unquote(charset), int)
        assert char_in == char_out, "Expected #{<<char_in>>} but got #{<<char_out>>}"
      end
    end
  end
end
