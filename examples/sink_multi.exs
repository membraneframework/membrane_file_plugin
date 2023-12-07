Mix.install([
  {:membrane_core, "~> 1.0"},
  {:membrane_file_plugin, path: Path.expand(__DIR__ <> "/..")}
])

# Filter responsible for generating split events
defmodule Splitter do
  @moduledoc """
  Receives buffer and splits it into two buffers
  of size `head_size` and `buffer.size - head_size`,
  sending a split event to multisink in between.
  """

  use Membrane.Filter

  alias Membrane.Buffer
  alias Membrane.File.SplitEvent

  def_input_pad :input, flow_control: :auto, accepted_format: Membrane.RemoteStream
  def_output_pad :output, flow_control: :auto, accepted_format: Membrane.RemoteStream

  def_options head_size: [type: :integer]

  def handle_init(_ctx, opts) do
    {[], opts |> Map.from_struct() |> Map.put(:split?, true)}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, %{head_size: head_size, split?: true}) do
    <<head::binary-size(head_size), tail::binary>> = buffer.payload

    actions = [
      buffer: {:output, %Buffer{payload: head}},
      event: {:output, %SplitEvent{}},
      buffer: {:output, %Buffer{payload: tail}}
    ]

    { actions, %{split?: false}}
  end

  def handle_buffer(:input, buffer, _ctx, %{split?: false}) do
    {[buffer: {:output, buffer}], %{split?: false}}
  end
end

:ok = File.write!("input.bin", <<0::integer-unit(8)-size(1024)>>)

defmodule SinkMultiExamplePipeline do
  @moduledoc """
  Example pipeline that reads a binary file
  and performs a multisink split when sending it forward.
  """

  use Membrane.Pipeline

  @doc false
  @impl true
  def handle_init(_ctx, target) do
    spec = [
      child(:file_source, %Membrane.File.Source{location: "input.bin"})
      |> child(:filter, %Splitter{head_size: 10})
      |> child(:file_sink, %Membrane.File.Sink.Multi{location: "/tmp/output", extension: ".bin"})
    ]

    {[spec: spec], %{target: target}}
  end

  @impl true
  def handle_element_end_of_stream(:file_sink, :input, _ctx, state) do
    send(state.target, :done)
    {[], state}
  end

  def handle_element_end_of_stream(_elem, _pad, _ctx, state) do
    {[], state}
  end
end

{:ok, _supervisor_pid, pid} = Membrane.Pipeline.start_link(SinkMultiExamplePipeline, self())

receive do
  :done -> Membrane.Pipeline.terminate(pid)
end
