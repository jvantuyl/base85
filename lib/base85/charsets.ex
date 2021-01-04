defmodule Base85.Charsets do
  @moduledoc """
  Implements various character sets used for Base85 encoding.
  """
  # These are charlists, since I actually want a list of chars.
  @spec charsets() :: %{atom() => charlist()}
  def charsets() do
    %{
      safe85:
        '!$()*+,-.0123456789:;=>@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz{|}~',
      zeromq:
        '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-:+=^!/*?&<>()[]{}@%$#',
      postgresql:
        '!/()*+,.0123456789:;=<>@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz{|}~'
    }
  end
end
