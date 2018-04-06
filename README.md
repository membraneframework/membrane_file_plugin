# Membrane Multimedia Framework: File Element

This package provides elements that can be used to read from and write to files.

# Sample usage

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
      {:file_src, :source} => {:file_sink, :sink},
    }

    {{:ok, %Spec{children: children, links: links}}, %{}}
  end
end

```
