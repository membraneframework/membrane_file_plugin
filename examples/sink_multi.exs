Mix.install([
  {:membrane_core, "~> 1.0"},
  {:membrane_file_plugin, path: Path.expand(__DIR__ <> "/..")}
])

# Filter responsible for generating split events
defmodule Splitter do
  use Membrane.Filter

  alias Membrane.Buffer
  alias Membrane.File.SplitEvent

  def_input_pad :input, demand_unit: :bytes, demand_mode: :auto, accepted_format: Membrane.RemoteStream
  def_output_pad :output, demand_mode: :auto, accepted_format: Membrane.RemoteStream

  def_options head_size: [type: :integer]

  def handle_init(_ctx, opts) do
    {[], opts |> Map.from_struct() |> Map.put(:split?, true)}
  end

  @impl true
  def handle_process(:input, buffer, _ctx, %{head_size: head_size, split?: true}) do
    <<head::binary-size(head_size), tail::binary>> = buffer.payload

    actions = [
      buffer: {:output, %Buffer{payload: head}},
      event: {:output, %SplitEvent{}},
      buffer: {:output, %Buffer{payload: tail}}
    ]

    { actions, %{split?: false}}
  end

  def handle_process(:input, buffer, _ctx, %{split?: false}) do
    {[buffer: {:output, buffer}], %{split?: false}}
  end
end

:ok = File.write!("input.bin", <<0::integer-unit(8)-size(1024)>>)

defmodule SinkMultiExamplePipeline do
  use Membrane.Pipeline

  @doc false
  @impl true
  def handle_init(_ctx, target) do
    structure = [
      child(:file_source, %Membrane.File.Source{location: "input.bin"})
      |> child(:filter, %Splitter{head_size: 10})
      |> child(:file_sink, %Membrane.File.Sink.Multi{location: "/tmp/output", extension: ".bin"})
    ]

    {[spec: structure, playback: :playing], %{target: target}}
  end

  @impl true
  def handle_element_end_of_stream({:file_sink, :input}, _ctx, state) do
    send(state.target, :done)
    {[], state}
  end

  def handle_element_end_of_stream(_other, _ctx, state) do
    {[], state}
  end
end

{:ok, _supervisor_pid, pid} = SinkMultiExamplePipeline.start_link(self())

receive do
  :done -> SinkMultiExamplePipeline.terminate(pid)
end
