# Membrane File plugin

[![Hex.pm](https://img.shields.io/hexpm/v/membrane_file_plugin.svg)](https://hex.pm/packages/membrane_file_plugin)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/membrane_file_plugin/)
[![CircleCI](https://circleci.com/gh/membraneframework/membrane_file_plugin.svg?style=svg)](https://circleci.com/gh/membraneframework/membrane_file_plugin)

Membrane plugin for reading and writing to files.

It is part of [Membrane Multimedia Framework](https://membraneframework.org).

## Installation

The package can be installed by adding `membrane_file_plugin` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:membrane_file_plugin, "~> 0.10.0"}
  ]
end
```

## Sample usage

Playing below pipeline should copy `/etc/passwd` to `./test`:

```elixir
defmodule FileExamplePipeline do
  use Membrane.Pipeline

  @doc false
  @impl true
  def handle_init(_) do
    children = [
      file_src: %Membrane.File.Source{location: "/etc/passwd"},
      file_sink: %Membrane.File.Sink{location: "./test"},
    ]
    links = [link(:file_src) |> to(:file_sink)]

    {{:ok, spec: %ParentSpec{children: children, links: links}}, %{}}
  end
end

```

## Copyright and License

Copyright 2018, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=membrane-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

Licensed under the [Apache License, Version 2.0](LICENSE)
