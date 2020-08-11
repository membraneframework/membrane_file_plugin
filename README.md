# Membrane Multimedia Framework: File Element

[![Hex.pm](https://img.shields.io/hexpm/v/membrane_element_file.svg)](https://hex.pm/packages/membrane_element_file)
[![CircleCI](https://circleci.com/gh/membraneframework/membrane-element-file.svg?style=svg)](https://circleci.com/gh/membraneframework/membrane-element-file)

This package provides elements that can be used to read from and write to files.

It is part of [Membrane Multimedia Framework](https://membraneframework.org).

## Sample usage

Playing below pipeline should copy `/etc/passwd` to `./test`:

```elixir
defmodule FileExamplePipeline do
  use Membrane.Pipeline
  alias Pipeline.Spec
  alias Membrane.Element.File

  @doc false
  @impl true
  def handle_init(_) do
    children = [
      file_src: %File.Source{location: "/etc/passwd"},
      file_sink: %File.Sink{location: "./test"},
    ]
    links = %{
      {:file_src, :output} => {:file_sink, :input},
    }

    {{:ok, %Spec{children: children, links: links}}, %{}}
  end
end

```

## Copyright and License

Copyright 2018, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=membrane-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

Licensed under the [Apache License, Version 2.0](LICENSE)
