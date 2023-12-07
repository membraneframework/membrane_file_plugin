Mix.install([
  {:membrane_core, "~> 1.0"},
  {:membrane_file_plugin, path: Path.expand(__DIR__ <> "/..")}
])

defmodule FileExamplePipeline do
  @doc """
  Example pipeline that reads its source code file and outputs it to /tmp/test.
  """

  use Membrane.Pipeline

  @doc false
  @impl true
  def handle_init(_ctx, target) do
    spec = [
      child(:file_src, %Membrane.File.Source{location: __ENV__.file})
      |> child(:file_sink, %Membrane.File.Sink{location: "/tmp/test"})
    ]

    {[spec: spec], %{target: target}}
  end

  @impl true
  def handle_element_end_of_stream(:file_sink, :input, _ctx, state) do
    send(state.target, :done)
    {[], state}
  end
end

{:ok, _supervisor_pid, pid} = Membrane.Pipeline.start_link(FileExamplePipeline, self())

receive do
  :done -> Membrane.Pipeline.terminate(pid)
end
