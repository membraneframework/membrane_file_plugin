# This script reads the file whose name is specified as the first argument, and outputs its contents to stdout, basically like `cat`.
# e.g. running `elixir examples/file_to_pipe.exs examples/file_to_pipe.exs` should output the contents of this file.
#
# if Mix pollutes the logs, consider redirecting its logs by overriding the
# [Mix.Shell](https://hexdocs.pm/mix/Mix.Shell.html) behaviour

Mix.start()
Mix.shell(Mix.Shell.Quiet)

Mix.install([{:membrane_file_plugin, path: __DIR__ <> "/.."}])

defmodule FileExamplePipeline do
  use Membrane.Pipeline

  @impl true
  def handle_init(_ctx, %{target: target, input: input}) do
    spec =
      child(%Membrane.File.Source{location: input})
      |> child(:sink, %Membrane.File.Sink{location: :stdout})

    {[spec: spec], %{target: target}}
  end

  @impl true
  def handle_element_end_of_stream(:sink, :input, _ctx, state) do
    send(state.target, :done)
    {[], state}
  end
end

Membrane.File.Sink.redirect_logs_to_stderr()

[input] = System.argv()

{:ok, _supervisor, pid} =
  Membrane.Pipeline.start_link(FileExamplePipeline, %{input: input, target: self()})

receive do
  :done -> Membrane.Pipeline.terminate(pid)
end
