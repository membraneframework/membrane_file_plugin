# This script reads from stdin until EOS, writing the contents to a file specified by the first argument
# The second argument is chunk size, specifying how many bytes to consume from stdin at once.
# The script can be run like this: `echo hello | elixir examples/pipe_to_file.exs /tmp/test 2048`, resulting in 'hello' being written to /tmp/test
#
# if Mix pollutes the logs, consider redirecting its logs by overriding the
# [Mix.Shell](https://hexdocs.pm/mix/Mix.Shell.html) behaviour

Mix.start()
Mix.shell(Mix.Shell.Quiet)

# setting different system_env is currently a workaround to make sure scripts do not share mix install dirs
Mix.install([{:membrane_file_plugin, path: "."}], system_env: [{"PID", :os.getpid()}])

defmodule PipeToFile do
  use Membrane.Pipeline

  @impl true
  def handle_init(_ctx, %{target: target, output: output, chunk_size: chunk_size}) do
    spec =
      child(%Membrane.File.Source{location: :stdin, chunk_size: chunk_size})
      |> child(:sink, %Membrane.File.Sink{location: output})

    {[spec: spec], %{target: target}}
  end

  @impl true
  def handle_element_end_of_stream(:sink, :input, _ctx, state) do
    send(state.target, :done)
    {[], state}
  end
end

[output_file, chunk_size_str] = System.argv()
{chunk_size, ""} = Integer.parse(chunk_size_str)

{:ok, _supervisor, pid} =
  Membrane.Pipeline.start_link(PipeToFile, %{
    target: self(),
    output: output_file,
    chunk_size: chunk_size
  })

receive do
  :done -> Membrane.Pipeline.terminate(pid)
end
