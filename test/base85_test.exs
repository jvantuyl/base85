defmodule Base85Test do
  use ExUnit.Case, async: true
  doctest Base85.Encode
  doctest Base85.Decode

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
        # get something random enough
        test_seed = ExUnit.configuration()[:seed]
        :rand.seed(:exsss, {test_seed + @num, test_seed * @num, test_seed * @num * 13})

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
    assert_raise Base85.UnrecognizedPadding, fn ->
      Base85.encode!("abc", charset: :zeromq, padding: :weird)
    end

    assert_raise Base85.UnrecognizedPadding, fn ->
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
      Base85.encode!("abc", charset: :zeromq, padding: :none)
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
    assert {:error, :unrecognized_padding} =
             Base85.encode("abc", charset: :zeromq, padding: :weird)

    assert {:error, :unrecognized_padding} =
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
end
