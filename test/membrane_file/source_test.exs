defmodule Membrane.File.SourceTest do
  use ExUnit.Case
  use Mockery
  use Membrane.File.TestSupport.Common, module: Membrane.File.Source

  alias Membrane.File.CommonFile
  alias Membrane.Buffer

  @module Membrane.File.Source

  defp state(_ctx) do
    %{state: %{location: "", chunk_size: nil, fd: nil}}
  end

  setup_all :state

  describe "handle_demand buffers" do
    setup :inject_mock_fd

    test "should send chunk of size state.chunk_size", %{state: state} do
      state = %{state | chunk_size: 5}
      mock(CommonFile, [binread!: 2], fn _file, 5 -> <<1, 2, 3, 4, 5>> end)

      assert {{:ok, actions}, ^state} = @module.handle_demand(:output, 1, :buffers, nil, state)

      assert actions == [
               buffer: {:output, %Buffer{payload: <<1, 2, 3, 4, 5>>}},
               redemand: :output
             ]
    end

    test "should send chunk and eos event when reads until eof", %{state: state} do
      state = %{state | chunk_size: 5}
      mock(CommonFile, [binread!: 2], fn _file, 5 -> <<1, 2>> end)

      assert {{:ok, actions}, ^state} = @module.handle_demand(:output, 1, :buffers, nil, state)
      assert actions == [buffer: {:output, %Buffer{payload: <<1, 2>>}}, end_of_stream: :output]
    end

    test "should send eos event on eof", %{state: state} do
      state = %{state | chunk_size: 5}
      mock(CommonFile, [binread!: 2], :eof)

      assert @module.handle_demand(:output, 1, :buffers, nil, state) ==
               {{:ok, end_of_stream: :output}, state}
    end
  end

  describe "handle_demand bytes" do
    test "should send chunk of given size when demand in bytes", %{state: state} do
      mock(CommonFile, [binread!: 2], fn _file, 5 -> <<1, 2, 3, 4, 5>> end)

      assert @module.handle_demand(:output, 5, :bytes, nil, state) ==
               {{:ok, buffer: {:output, %Buffer{payload: <<1, 2, 3, 4, 5>>}}}, state}
    end

    test "should send chunk and eos event when reads until eof", %{state: state} do
      mock(CommonFile, [binread!: 2], fn _file, 5 -> <<1, 2>> end)

      assert {{:ok, actions}, ^state} = @module.handle_demand(:output, 5, :bytes, nil, state)
      assert actions == [buffer: {:output, %Buffer{payload: <<1, 2>>}}, end_of_stream: :output]
    end

    test "should send eos event on eof", %{state: state} do
      mock(CommonFile, [binread!: 2], fn _file, 5 -> :eof end)

      assert {{:ok, end_of_stream: :output}, state} ==
               @module.handle_demand(:output, 5, :bytes, nil, state)
    end
  end
end
