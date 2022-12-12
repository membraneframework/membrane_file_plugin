defmodule Membrane.File.SourceTest do
  use Membrane.File.TestCaseTemplate, module: Membrane.File.Source, async: true

  alias Membrane.Buffer
  alias Membrane.File.CommonMock

  @module Membrane.File.Source

  defp state_and_ctx(_ctx) do
    %{
      ctx: nil,
      state: %{location: "", chunk_size: nil, fd: nil}
    }
  end

  setup :state_and_ctx

  describe "handle_demand buffers" do
    setup :inject_mock_fd

    test "should send chunk of size state.chunk_size", %{state: state, ctx: ctx} do
      state = %{state | chunk_size: 5}

      CommonMock
      |> expect(:binread!, fn _file, 5 -> <<1, 2, 3, 4, 5>> end)

      assert {actions, ^state} = @module.handle_demand(:output, 1, :buffers, ctx, state)

      assert actions == [
               buffer: {:output, %Buffer{payload: <<1, 2, 3, 4, 5>>}},
               redemand: :output
             ]
    end

    test "should send chunk and eos event when reads until eof", %{state: state, ctx: ctx} do
      state = %{state | chunk_size: 5}

      CommonMock
      |> expect(:binread!, fn _file, 5 -> <<1, 2>> end)

      assert {actions, ^state} = @module.handle_demand(:output, 1, :buffers, ctx, state)
      assert actions == [buffer: {:output, %Buffer{payload: <<1, 2>>}}, end_of_stream: :output]
    end

    test "should send eos event on eof", %{state: state, ctx: ctx} do
      state = %{state | chunk_size: 5}

      CommonMock
      |> expect(:binread!, fn _file, 5 -> :eof end)

      assert @module.handle_demand(:output, 1, :buffers, ctx, state) ==
               {[end_of_stream: :output], state}
    end
  end

  describe "handle_demand bytes" do
    test "should send chunk of given size when demand in bytes", %{state: state, ctx: ctx} do
      CommonMock
      |> expect(:binread!, fn _file, 5 -> <<1, 2, 3, 4, 5>> end)

      assert @module.handle_demand(:output, 5, :bytes, ctx, state) ==
               {[buffer: {:output, %Buffer{payload: <<1, 2, 3, 4, 5>>}}], state}
    end

    test "should send chunk and eos event when reads until eof", %{state: state, ctx: ctx} do
      CommonMock
      |> expect(:binread!, fn _file, 5 -> <<1, 2>> end)

      assert {actions, ^state} = @module.handle_demand(:output, 5, :bytes, ctx, state)
      assert actions == [buffer: {:output, %Buffer{payload: <<1, 2>>}}, end_of_stream: :output]
    end

    test "should send eos event on eof", %{state: state, ctx: ctx} do
      CommonMock
      |> expect(:binread!, fn _file, 5 -> :eof end)

      assert {[end_of_stream: :output], state} ==
               @module.handle_demand(:output, 5, :bytes, ctx, state)
    end
  end
end
