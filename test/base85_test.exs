defmodule Base85Test do
  use ExUnit.Case, async: true

  @known_strings %{
    {:postgresql, :none} => {<<98, 164, 78, 239, 145, 174, 115, 219>>, "HelloWorld"},
    {:postgresql, :pkcs7} => {<<98, 164, 78, 239, 145, 174, 115, 219>>, "HelloWorld/Aer8"},
    {:safe85, :none} => {<<0x62, 0xA4, 0x4E, 0xEF, 0x91, 0xAE, 0x73, 0xDB>>, "HelloWorld"},
    {:safe85, :pkcs7} => {<<0x62, 0xA4, 0x4E, 0xEF, 0x91, 0xAE, 0x73, 0xDB>>, "HelloWorld$Aer7"},
    {:zeromq, :none} => {<<0x86, 0x4F, 0xD2, 0x6F, 0xB5, 0x59, 0xF7, 0x5B>>, "HelloWorld"},
    {:zeromq, :pkcs7} => {<<0x86, 0x4F, 0xD2, 0x6F, 0xB5, 0x59, 0xF7, 0x5B>>, "HelloWorld1oX&g"}
  }

  for charset <- [:safe85, :zeromq, :postgresql], padding <- [:none, :pkcs7] do
    @charset charset
    @padding padding
    test "encodes null string, #{@charset}:#{@padding}" do
      assert Base85.encode!(<<>>, charset: @charset, padding: @padding) == <<>>
    end

    test "decodes null string, #{@charset}:#{@padding}" do
      assert Base85.decode!(<<>>, charset: @charset, padding: @padding) == <<>>
    end

    test "encodes known string, #{@charset}:#{@padding}" do
      {dec, enc} = @known_strings[{@charset, @padding}]

      assert Base85.encode!(dec, charset: @charset, padding: @padding) == enc
    end

    test "decodes known string, #{@charset}:#{@padding}" do
      {dec, enc} = @known_strings[{@charset, @padding}]

      assert Base85.decode!(enc, charset: @charset, padding: @padding) == dec
    end

    for num <- 1..64 do
      @num num
      test "round-trips random string ##{@num}, #{@charset}:#{@padding}" do
        binlen =
          if @padding == :none do
            div(Enum.random(32..256), 4) * 4
          else
            Enum.random(32..256)
          end

        randcharlist = for _ <- 1..binlen, do: Enum.random(0..255)
        randbin = :erlang.list_to_binary(randcharlist)

        assert Base85.encode!(randbin, charset: @charset, padding: @padding)
               |> Base85.decode!(charset: @charset, padding: @padding) == randbin
      end
    end
  end

  test "bad charset (exception)" do
    assert_raise Base85.UnrecognizedCharacterSet, fn ->
      Base85.encode!("abc", charset: :weird, padding: :none)
    end

    assert_raise Base85.UnrecognizedCharacterSet, fn ->
      Base85.decode!("abc", charset: :weird, padding: :none)
    end
  end

  test "bad padding (exception)" do
    assert_raise Base85.UnrecognizedPaddingMethod, fn ->
      Base85.encode!("abc", charset: :zeromq, padding: :weird)
    end

    assert_raise Base85.UnrecognizedPaddingMethod, fn ->
      Base85.decode!("abc", charset: :zeromq, padding: :weird)
    end
  end

  test "bad encoded length (exception)" do
    assert_raise Base85.InvalidEncodedLength, fn ->
      # should be a multiple of 5
      Base85.decode!("abc", charset: :zeromq, padding: :none)
    end
  end

  test "bad unencoded length (exception)" do
    assert_raise(Base85.InvalidUnencodedLength, fn ->
      # should be a multiple of 4
      Base85.encode!("!!!", charset: :safe85, padding: :none)
    end)
  end

  test "bad characters (exception)" do
    assert_raise(Base85.InvalidCharacterForCharacterSet, fn ->
      Base85.decode!(~S(ab\de), charset: :safe85, padding: :none)
    end)
  end

  test "bad padding bytes (exception)" do
    assert_raise(Base85.InvalidPaddingData, fn ->
      Base85.decode!("abcdeabcde", charset: :zeromq, padding: :pkcs7)
    end)
  end

  test "default options round-trip works (pkcs7)" do
    original = "hello world"
    encoded = Base85.encode!(original, padding: :pkcs7)
    decoded = Base85.decode!(encoded, padding: :pkcs7)
    assert decoded == original
  end

  test "default options round-trip works for various lengths" do
    for len <- 1..20 do
      original = :crypto.strong_rand_bytes(len)
      encoded = Base85.encode!(original)
      decoded = Base85.decode!(encoded)
      assert decoded == original, "failed for length #{len}"
    end
  end

  test "none padding encode validates input length" do
    # Already covered by existing test, but let's be explicit
    assert_raise(Base85.InvalidUnencodedLength, fn ->
      # 3 bytes, not multiple of 4
      Base85.encode!("abc", padding: :none)
    end)

    # Valid multiple of 4 should work
    # 4 bytes, OK
    Base85.encode!("abcd", padding: :none)
    # 8 bytes, OK
    Base85.encode!("abcdabcd", padding: :none)
  end

  test "none padding works correctly when input is valid" do
    # 8 bytes input (multiple of 4)
    original = "abcdabcd"
    encoded = Base85.encode!(original, padding: :none)
    decoded = Base85.decode!(encoded, padding: :none)
    assert decoded == original
  end

  @tag :skip
  test "internal error (exception)" do
    # currently there's no good way to trigger this
  end

  test "bad charset (error tuple)" do
    assert {:error, :unrecognized_character_set} =
             Base85.encode("abc", charset: :weird, padding: :none)

    assert {:error, :unrecognized_character_set} =
             Base85.decode("abc", charset: :weird, padding: :none)
  end

  test "bad padding (error tuple)" do
    assert {:error, :unrecognized_padding_method} =
             Base85.encode("abc", charset: :zeromq, padding: :weird)

    assert {:error, :unrecognized_padding_method} =
             Base85.decode("abc", charset: :zeromq, padding: :weird)
  end

  test "bad encoded length (error tuple)" do
    # should be a multiple of 5
    assert {:error, :invalid_encoded_length} =
             Base85.decode("abc", charset: :zeromq, padding: :none)
  end

  test "bad unencoded length (error tuple)" do
    # should be a multiple of 4
    assert {:error, :invalid_unencoded_length} =
             Base85.encode("abc", charset: :zeromq, padding: :none)
  end

  test "bad characters (error tuple)" do
    assert {:error, :invalid_character_for_character_set} =
             Base85.decode(~S(ab\de), charset: :safe85, padding: :none)
  end

  test "bad padding bytes (error tuple)" do
    assert {:error, :invalid_padding_data} =
             Base85.decode("abcdeabcde", charset: :zeromq, padding: :pkcs7)
  end

  @tag :skip
  test "internal error (error tuple)" do
    # currently there's no good way to trigger this
  end

  # ASCII85 padding tests
  test "complete group (4 bytes) - no truncation needed" do
    # 4 bytes -> 5 encoded chars, no padding/truncation
    original = "abcd"
    encoded = Base85.encode!(original, padding: :ascii85)
    assert byte_size(encoded) == 5
    decoded = Base85.decode!(encoded, padding: :ascii85)
    assert decoded == original
  end

  test "3 of 4 bytes - pad 1, truncate 1" do
    # 3 bytes -> pad with 1 zero -> encode to 5 chars -> truncate 1 -> 4 chars
    original = "abc"
    encoded = Base85.encode!(original, padding: :ascii85)
    assert byte_size(encoded) == 4
    decoded = Base85.decode!(encoded, padding: :ascii85)
    assert decoded == original
  end

  test "2 of 4 bytes - pad 2, truncate 2" do
    # 2 bytes -> pad with 2 zeros -> encode to 5 chars -> truncate 2 -> 3 chars
    original = "ab"
    encoded = Base85.encode!(original, padding: :ascii85)
    assert byte_size(encoded) == 3
    decoded = Base85.decode!(encoded, padding: :ascii85)
    assert decoded == original
  end

  test "1 of 4 bytes - pad 3, truncate 3" do
    # 1 byte -> pad with 3 zeros -> encode to 5 chars -> truncate 3 -> 2 chars
    original = "a"
    encoded = Base85.encode!(original, padding: :ascii85)
    assert byte_size(encoded) == 2
    decoded = Base85.decode!(encoded, padding: :ascii85)
    assert decoded == original
  end

  test "empty string" do
    assert Base85.encode!(<<>>, padding: :ascii85) == <<>>
    assert Base85.decode!(<<>>, padding: :ascii85) == <<>>
  end

  test "multiple complete groups (8 bytes)" do
    original = "abcdabcd"
    encoded = Base85.encode!(original, padding: :ascii85)
    assert byte_size(encoded) == 10
    decoded = Base85.decode!(encoded, padding: :ascii85)
    assert decoded == original
  end

  test "multiple groups with partial (9 bytes = 2 full + 1 byte)" do
    original = "abcdabcde"
    encoded = Base85.encode!(original, padding: :ascii85)
    # 8 bytes -> 10 chars, 1 byte -> 2 chars = 12 chars total
    assert byte_size(encoded) == 12
    decoded = Base85.decode!(encoded, padding: :ascii85)
    assert decoded == original
  end

  test "invalid encoded length (remainder 1) raises error" do
    assert_raise Base85.InvalidEncodedLength, fn ->
      # 6 chars has remainder 1 when divided by 5, which is invalid
      Base85.decode!("abcdef", padding: :ascii85)
    end
  end

  test "round-trip works for all valid lengths 1-20" do
    for len <- 1..20 do
      original = :crypto.strong_rand_bytes(len)
      encoded = Base85.encode!(original, padding: :ascii85)
      decoded = Base85.decode!(encoded, padding: :ascii85)
      assert decoded == original, "failed for length #{len}"
    end
  end

  test "works with different charsets" do
    original = "hello"

    for charset <- [:safe85, :zeromq, :postgresql] do
      encoded = Base85.encode!(original, charset: charset, padding: :ascii85)
      decoded = Base85.decode!(encoded, charset: charset, padding: :ascii85)
      assert decoded == original, "failed for charset #{charset}"
    end
  end

  test "encoded length follows expected pattern" do
    # For n input bytes:
    # - full groups of 4 bytes -> 5 chars each
    # - remaining r bytes (1-3) -> r+1 chars
    for len <- 1..32 do
      original = :crypto.strong_rand_bytes(len)
      encoded = Base85.encode!(original, padding: :ascii85)

      full_groups = div(len, 4)
      remainder = rem(len, 4)

      expected_len =
        full_groups * 5 +
          case remainder do
            0 -> 0
            r -> r + 1
          end

      assert byte_size(encoded) == expected_len,
             "length #{len}: expected #{expected_len} encoded chars, got #{byte_size(encoded)}"
    end
  end
end
