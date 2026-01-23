defmodule Base85.QuirksTest do
  use ExUnit.Case, async: true
  alias Base85.Quirks

  @quirk_tests [
    # zero hack on
    {:safe85, [zero_hack: true], "!!!!!", "z"},
    {:ascii85, [zero_hack: true], "!!!!!", "z"},
    {:zeromq, [zero_hack: true], "00000", "z"},
    {:postgresql, [zero_hack: true], "!!!!!", "z"},
    # zero hack off
    {:safe85, [zero_hack: false], "!!!!!", "!!!!!"},
    {:ascii85, [zero_hack: false], "!!!!!", "!!!!!"},
    {:zeromq, [zero_hack: false], "00000", "00000"},
    {:postgresql, [zero_hack: false], "!!!!!", "!!!!!"},
    # space hack on
    {:safe85, [space_hack: true], "1D_mT", "y"},
    {:ascii85, [space_hack: true], "+<VdL", "y"},
    {:zeromq, [space_hack: true], "arR^H", "y"},
    {:postgresql, [space_hack: true], "2D_mT", "y"},
    # space hack off
    {:safe85, [space_hack: false], "1D_mT", "1D_mT"},
    {:ascii85, [space_hack: false], "+>VdL", "+>VdL"},
    {:zeromq, [space_hack: false], "arR^H", "arR^H"},
    {:postgresql, [space_hack: false], "2D_mT", "2D_mT"}
  ]

  for {charset, quirk_opts, unenc, enc} <- @quirk_tests,
      reduce: 0 do
    test_idx ->
      test "quirks: round-trip quirks through #{inspect(charset)} w/ #{inspect(quirk_opts)} (#{test_idx})" do
        quirk_encoder =
          Quirks.quirk_encoder(charset: unquote(charset), quirks: unquote(quirk_opts))

        quirk_decoder =
          Quirks.quirk_decoder(charset: unquote(charset), quirks: unquote(quirk_opts))

        enc =
          [unquote(unenc)]
          |> quirk_encoder.()
          |> Enum.to_list()
          |> IO.iodata_to_binary()

        assert enc == unquote(enc)

        dec =
          [enc]
          |> quirk_decoder.()
          |> Enum.to_list()
          |> IO.iodata_to_binary()

        assert dec == unquote(unenc)
      end

      test_idx + 1
  end
end
