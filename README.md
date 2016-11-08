# Membrane Multimedia Framework: File Element

This package provides elements that can be used to read from and write to files.

# Installation

Add the following line to your `deps` in `mix.exs`.  Run `mix deps.get`.

```elixir
{:membrane_element_file, git: "git@bitbucket.org:radiokit/membrane-element-file.git"}
```

Then add the following line to your `applications` in `mix.exs`.

```elixir
:membrane_element_file
```

# Sample usage

This should copy `/etc/passwd` to `./test`:

```elixir
{:ok, sink} = Membrane.Element.File.Sink.start_link(%Membrane.Element.File.SinkOptions{location: "./test"})
Membrane.Element.File.Sink.play(sink)

{:ok, source} = Membrane.Element.File.Source.start_link(%Membrane.Element.File.SourceOptions{location: "/etc/passwd"})
Membrane.Element.File.Source.link(source, sink)
Membrane.Element.File.Source.play(source)
```

# Authors

Marcin Lewandowski
