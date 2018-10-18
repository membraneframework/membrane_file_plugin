# Membrane Multimedia Framework: File Element

[![Build Status](https://travis-ci.com/membraneframework/membrane-element-file.svg?branch=master)](https://travis-ci.com/membraneframework/membrane-element-file)

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
      {:file_src, :source} => {:file_sink, :file_sink},
    }

    {{:ok, %Spec{children: children, links: links}}, %{}}
  end
end

```
