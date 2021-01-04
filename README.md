# Base85

Implements some base-85 character encodings.

Supported character sets include:
- ZeroMQ's Z85
- Safe85 (character set only, not padding)
- PostgreSQL-safe

Supported padding methods include:
- None
- PKCS7-style

Note that this currently does *not* implement padding used for full support of
Safe85 or Safe85L.

Unsupported character sets include:
- btoa
- ZModem Pack-7
- Adobe ASCII85

## Installation

This package is [available in Hex](https://hex.pm/). The package can be
installed by adding `base85` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:base85, "~> 0.1.0"}
  ]
end
```

Documentation is generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). The docs can
be found at [https://hexdocs.pm/base85](https://hexdocs.pm/base85).

