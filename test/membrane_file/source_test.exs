defmodule Membrane.File.SourceTest do
  use Membrane.File.TestSupport.Boilerplate, for: Membrane.File.Source

  defp state(_ctx) do
    %{state: %{location: "", chunk_size: nil, fd: nil}}
  end

  setup_all [:state, :inject_mock_fd]

  describe "handle_demand buffers" do
    setup %{state: state} do
      %{state: %{state | chunk_size: 5}}
    end

    test "should send chunk of size state.chunk_size", %{state: state} do
      %{fd: file, chunk_size: chunk_size} = state
      chunk = <<1::size(chunk_size)-unit(8)>>

      patch(CommonFile, :binread, chunk)

      assert {{:ok, buffer: {:output, %Buffer{payload: ^chunk}}, redemand: :output}, ^state} =
               @module.handle_demand(:output, nil, :buffers, nil, state)

      assert_called_once(CommonFile.binread(^file, ^chunk_size))
    end

    test "should send eos event on eof", %{state: state} do
      %{fd: file, chunk_size: chunk_size} = state

      patch(CommonFile, :binread, :eof)

      assert {{:ok, end_of_stream: :output}, state} ==
               @module.handle_demand(:output, nil, :buffers, nil, state)

      assert_called_once(CommonFile.binread(^file, ^chunk_size))
    end
  end

  describe "handle_demand bytes" do
    test "should send chunk of given size when demand in bytes", %{state: state} do
      %{fd: file} = state
      chunk_size = 10
      chunk = <<1::size(chunk_size)-unit(8)>>

      patch(CommonFile, :binread, chunk)

      assert {{:ok, buffer: {:output, %Buffer{payload: ^chunk}}}, ^state} =
               @module.handle_demand(:output, chunk_size, :bytes, nil, state)

      assert_called_once(CommonFile.binread(^file, ^chunk_size))
    end

    test "should send eos event on eof", %{state: state} do
      %{fd: file} = state
      chunk_size = 10

      patch(CommonFile, :binread, :eof)

      assert {{:ok, end_of_stream: :output}, state} ==
               @module.handle_demand(:output, chunk_size, :bytes, nil, state)

      assert_called_once(CommonFile.binread(^file, ^chunk_size))
    end
  end
end
