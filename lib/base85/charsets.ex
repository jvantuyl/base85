defmodule Base85.Charsets do
  @moduledoc """
  Implements various character sets used for Base85 encoding.
  """
  # These are charlists, since I actually want a list of chars.
  @typedoc "available character sets"
  @type charset :: :safe85 | :zeromq | :postgresql

  @doc """
  Returns a map of character sets.
  """
  @spec charsets() :: %{charset() => charlist()}
  def charsets() do
    %{
      safe85:
        ~c"!$()*+,-.0123456789:;=>@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz{|}~",
      zeromq:
        ~c"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-:+=^!/*?&<>()[]{}@%$#",
      postgresql:
        ~c"!/()*+,.0123456789:;=<>@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz{|}~"
    }
  end
end
