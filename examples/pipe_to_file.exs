Mix.start()
Mix.shell(Mix.Shell.Quiet)

Mix.install(
  [
    {:membrane_file_plugin, path: "."}
  ]
  # force: true
)

[output, chunk_size_str | _] = System.argv()
{chunk_size, ""} = Integer.parse(chunk_size_str)

defmodule PipeToFile do
  @doc """
  Example pipeline that reads its source code file and outputs it to /tmp/test.
  """

  use Membrane.Pipeline

  @doc false
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

{:ok, _supervisor, pid} =
  Membrane.Pipeline.start_link(PipeToFile, %{
    target: self(),
    output: output,
    chunk_size: chunk_size
  })

receive do
  :done -> Membrane.Pipeline.terminate(pid)
end
