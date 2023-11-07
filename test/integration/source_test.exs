defmodule Membrane.File.Integration.SourceTest do
  use Membrane.File.IntegrationTestCaseTemplate

  import Membrane.Testing.Assertions
  import Membrane.ChildrenSpec

  alias Membrane.Testing.Pipeline
  alias Membrane.Testing.Sink
  alias Membrane.File.Source
  alias Membrane.File.SeekSourceEvent
  alias Membrane.Buffer

  defmodule Filter do
    use Membrane.Filter

    def_input_pad :input,
      accepted_format: _,
      flow_control: :auto

    def_output_pad :output, accepted_format: _, flow_control: :auto

    @impl true
    def handle_parent_notification(event, _context, state) do
      {[event: {:input, event}], state}
    end

    @impl true
    def handle_buffer(:input, buffer, _context, state) do
      {[buffer: {:output, buffer}], state}
    end
  end

  @input_text_file "test/fixtures/input.txt"

  test "if seekable Source sents only the buffers requested" do
    spec = [
      child(:source, %Source{
        location: @input_text_file,
        seekable?: true
      })
      |> child(:filter, Filter)
      |> child(:sink, Sink)
    ]

    {:ok, _supervisor_pid, pipeline_pid} = Pipeline.start(spec: spec)
    refute_sink_buffer(pipeline_pid, :sink, _)

    Pipeline.execute_actions(pipeline_pid,
      notify_child: {:filter, %SeekSourceEvent{start: 2, size_to_read: 5}}
    )

    assert_sink_buffer(pipeline_pid, :sink, %Buffer{payload: "23456"})

    Pipeline.execute_actions(pipeline_pid,
      notify_child: {:filter, %SeekSourceEvent{start: 0, size_to_read: 3}}
    )

    Pipeline.execute_actions(pipeline_pid,
      notify_child: {:filter, %SeekSourceEvent{start: 7, size_to_read: 10}}
    )

    assert_sink_buffer(pipeline_pid, :sink, %Buffer{payload: "789"})

    Pipeline.execute_actions(pipeline_pid,
      notify_child: {:filter, %SeekSourceEvent{start: 7, size_to_read: 10, last?: true}}
    )

    assert_sink_buffer(pipeline_pid, :sink, %Buffer{payload: "789"})
    assert_end_of_stream(pipeline_pid, :sink)
  end

  test "if seekable Source sents :end_of_stream for seek event with `last?: true` when all the bytes are supplied" do
    Membrane.File.CommonMock.open!("test/fixtures/input.txt", [])

    spec = [
      child(:source, %Source{
        location: @input_text_file,
        seekable?: true
      })
      |> child(:filter, Filter)
      |> child(:sink, Sink)
    ]

    {:ok, _supervisor_pid, pipeline_pid} = Pipeline.start(spec: spec)
    refute_sink_buffer(pipeline_pid, :sink, _)

    Pipeline.execute_actions(pipeline_pid,
      notify_child: {:filter, %SeekSourceEvent{start: 0, size_to_read: 5, last?: true}}
    )

    assert_sink_buffer(pipeline_pid, :sink, %Buffer{payload: "01234"})
    assert_end_of_stream(pipeline_pid, :sink)
  end
end
