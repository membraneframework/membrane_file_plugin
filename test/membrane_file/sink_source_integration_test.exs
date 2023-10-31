defmodule Membrane.File.SinkSourceIntegrationTest do
  use ExUnit.Case, async: false

  import Membrane.ChildrenSpec
  import Membrane.Testing.Assertions
  import Mox, only: [set_mox_global: 1]

  alias Membrane.Buffer
  alias Membrane.File, as: MbrFile
  alias Membrane.Testing.{Source, Pipeline}

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
    structure = [
      child(:file_source, %MbrFile.Source{location: ctx.input_path})
      |> child(:file_sink, %MbrFile.Sink{location: ctx.output_path})
    ]

    assert {:ok, _supervisor_pid, pid} = Pipeline.start_link(structure: structure)
    assert_start_of_stream(pid, :file_sink, :input)
    assert_end_of_stream(pid, :file_sink, :input, 5_000)
    Pipeline.terminate(pid, blocking?: true)

    assert File.read!(ctx.output_path) == ctx.content
  end

  test "Sink temporary file merge when pipeline terminates", ctx do
    expected_content = """
    Roses are red,
    Violets are blue,
    If you're reading this,
    I'm sorry for you.
    """

    {first_part, second_part} = String.split_at(expected_content, 32)

    actions = [
      {:buffer, {:output, %Buffer{payload: second_part}}},
      {:event, {:output, %MbrFile.SeekSinkEvent{position: :bof, insert?: true}}},
      {:buffer, {:output, %Buffer{payload: first_part}}},
      {:end_of_stream, :output}
    ]

    generator = fn state, _size -> {actions, state} end

    structure = [
      child(:testing_source, %Source{output: {nil, generator}})
      |> child(:file_sink, %MbrFile.Sink{location: ctx.output_path})
    ]

    assert pid = Pipeline.start_link_supervised!(structure: structure)
    assert_start_of_stream(pid, :file_sink, :input)
    assert_end_of_stream(pid, :file_sink, :input, 5_000)
    Pipeline.terminate(pid, blocking?: true)

    assert File.read!(ctx.output_path) == expected_content
  end

  defmodule EmptyFilter do
    use Membrane.Filter

    def_input_pad :input, accepted_format: Membrane.RemoteStream
    def_output_pad :output, accepted_format: Membrane.RemoteStream

    @impl true
    def handle_buffer(:input, buffer, _ctx, state) do
      {[buffer: {:output, buffer}], state}
    end
  end

  test "File copy with filter", ctx do
    structure = [
      child(:file_source, %MbrFile.Source{location: ctx.input_path})
      |> child(:filter, EmptyFilter)
      |> child(:file_sink, %MbrFile.Sink{location: ctx.output_path})
    ]

    assert {:ok, _supervisor_pid, pid} = Pipeline.start_link(structure: structure)
    assert_start_of_stream(pid, :file_sink, :input)
    assert_end_of_stream(pid, :file_sink, :input, 5_000)
    Pipeline.terminate(pid, blocking?: true)

    assert File.read!(ctx.output_path) == ctx.content
  end

  defmodule Splitter do
    use Membrane.Filter

    alias Membrane.Buffer
    alias Membrane.File.SplitEvent

    def_input_pad :input, accepted_format: Membrane.RemoteStream
    def_output_pad :output, accepted_format: Membrane.RemoteStream

    def_options head_size: [type: :integer]

    @impl true
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

      {actions, %{split?: false}}
    end

    def handle_buffer(:input, buffer, _ctx, %{split?: false}) do
      {[buffer: {:output, buffer}], %{split?: false}}
    end
  end

  test "MultiSink with splitter", ctx do
    head_size = 10

    structure = [
      child(:file_source, %MbrFile.Source{location: ctx.input_path})
      |> child(:filter, %Splitter{head_size: head_size})
      |> child(:file_sink, %MbrFile.Sink.Multi{location: ctx.output_path, extension: ".bin"})
    ]

    assert {:ok, _supervisor_pid, pid} = Pipeline.start_link(structure: structure)
    assert_start_of_stream(pid, :file_sink, :input)
    assert_end_of_stream(pid, :file_sink, :input, 5_000)
    Pipeline.terminate(pid, blocking?: true)

    assert File.read!(ctx.output_path <> "0.bin") == binary_part(ctx.content, 0, head_size)

    assert File.read!(ctx.output_path <> "1.bin") ==
             binary_part(ctx.content, head_size, ctx.input_size - head_size)
  end
end
