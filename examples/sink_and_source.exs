Mix.install([
  {:membrane_core, "~> 0.10.0"},
  {:membrane_file_plugin, path: Path.expand(__DIR__ <> "/..")}
])

defmodule FileExamplePipeline do
  use Membrane.Pipeline

  @doc false
  @impl true
  def handle_init(target) do
    links =
      [
        file_src: %Membrane.File.Source{location: __ENV__.file},
        file_sink: %Membrane.File.Sink{location: "/tmp/test"}
      ]
      |> ParentSpec.link_linear()

    {{:ok, spec: %ParentSpec{links: links}, playback: :playing}, %{target: target}}
  end

  @impl true
  def handle_element_end_of_stream({:file_sink, :input}, _ctx, state) do
    send(state.target, :done)
    {:ok, state}
  end
end

{:ok, pid} = FileExamplePipeline.start_link(self())

receive do
  :done -> FileExamplePipeline.terminate(pid)
end
