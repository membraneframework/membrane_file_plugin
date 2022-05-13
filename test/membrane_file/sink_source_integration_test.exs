defmodule Membrane.File.SinkSourceIntegrationTest do
  use ExUnit.Case, async: false

  import Membrane.Testing.Assertions
  import Mox, only: [set_mox_global: 1]

  alias Membrane.File, as: MbrFile
  alias Membrane.ParentSpec
  alias Membrane.Testing.Pipeline

  @moduletag :tmp_dir

  setup :set_mox_global

  setup %{tmp_dir: tmp_dir} do
    input_path = Path.join(tmp_dir, "input.bin")
    output_path = Path.join(tmp_dir, "output.bin")
    input_size = 10_240
    content = <<0::integer-unit(8)-size(input_size)>>
    :ok = File.write!(input_path, content)
    Mox.stub_with(Membrane.File.CommonMock, Membrane.File.CommonFile)
    [input_path: input_path, output_path: output_path, input_size: input_size, content: content]
  end

  test "File copy", ctx do
    children = [
      file_source: %MbrFile.Source{location: ctx.input_path},
      file_sink: %MbrFile.Sink{location: ctx.output_path}
    ]

    assert {:ok, pid} = Pipeline.start_link(links: ParentSpec.link_linear(children))
    assert_start_of_stream(pid, :file_sink, :input)
    assert_end_of_stream(pid, :file_sink, :input, 5_000)
    Pipeline.terminate(pid, blocking?: true)

    assert File.read!(ctx.output_path) == ctx.content
  end

  defmodule EmptyFilter do
    use Membrane.Filter

    def_input_pad :input, demand_unit: :bytes, demand_mode: :auto, caps: Membrane.RemoteStream
    def_output_pad :output, demand_mode: :auto, caps: Membrane.RemoteStream

    @impl true
    def handle_process(:input, buffer, _ctx, state) do
      {{:ok, buffer: {:output, buffer}}, state}
    end
  end

  test "File copy with filter", ctx do
    children = [
      file_source: %MbrFile.Source{location: ctx.input_path},
      filter: EmptyFilter,
      file_sink: %MbrFile.Sink{location: ctx.output_path}
    ]

    assert {:ok, pid} = Pipeline.start_link(links: ParentSpec.link_linear(children))
    assert_start_of_stream(pid, :file_sink, :input)
    assert_end_of_stream(pid, :file_sink, :input, 5_000)
    Pipeline.terminate(pid, blocking?: true)

    assert File.read!(ctx.output_path) == ctx.content
  end

  defmodule Splitter do
    use Membrane.Filter

    alias Membrane.Buffer
    alias Membrane.File.SplitEvent

    def_input_pad :input, demand_unit: :bytes, demand_mode: :auto, caps: Membrane.RemoteStream
    def_output_pad :output, demand_mode: :auto, caps: Membrane.RemoteStream

    def_options head_size: [type: :integer]

    @impl true
    def handle_init(opts) do
      {:ok, opts |> Map.from_struct() |> Map.put(:split?, true)}
    end

    @impl true
    def handle_process(:input, buffer, _ctx, %{head_size: head_size, split?: true}) do
      <<head::binary-size(head_size), tail::binary>> = buffer.payload

      actions = [
        buffer: {:output, %Buffer{payload: head}},
        event: {:output, %SplitEvent{}},
        buffer: {:output, %Buffer{payload: tail}}
      ]

      {{:ok, actions}, %{split?: false}}
    end

    def handle_process(:input, buffer, _ctx, %{split?: false}) do
      {{:ok, buffer: {:output, buffer}}, %{split?: false}}
    end
  end

  test "MultiSink with splitter", ctx do
    head_size = 10

    children = [
      file_source: %MbrFile.Source{location: ctx.input_path},
      filter: %Splitter{head_size: 10},
      file_sink: %MbrFile.Sink.Multi{location: ctx.output_path, extension: ".bin"}
    ]

    assert {:ok, pid} = Pipeline.start_link(links: ParentSpec.link_linear(children))
    assert_start_of_stream(pid, :file_sink, :input)
    assert_end_of_stream(pid, :file_sink, :input, 5_000)
    Pipeline.terminate(pid, blocking?: true)

    assert File.read!(ctx.output_path <> "0.bin") == binary_part(ctx.content, 0, head_size)

    assert File.read!(ctx.output_path <> "1.bin") ==
             binary_part(ctx.content, head_size, ctx.input_size - head_size)
  end
end
