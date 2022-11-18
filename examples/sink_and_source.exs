Mix.install([
  {:membrane_core, "~> 0.11"},
  {:membrane_file_plugin, path: Path.expand(__DIR__ <> "/..")}
])

defmodule FileExamplePipeline do
  use Membrane.Pipeline

  @doc false
  @impl true
  def handle_init(_ctx, target) do
    structure = [
      child(:file_src, %Membrane.File.Source{location: __ENV__.file})
      |> child(:file_sink, %Membrane.File.Sink{location: "/tmp/test"})
    ]

    {[spec: structure, playback: :playing], %{target: target}}
  end

  @impl true
  def handle_element_end_of_stream({:file_sink, :input}, _ctx, state) do
    send(state.target, :done)
    {[], state}
  end
end

{:ok, _supervisor_pid, pid} = FileExamplePipeline.start_link(self())

receive do
  :done -> FileExamplePipeline.terminate(pid)
end
