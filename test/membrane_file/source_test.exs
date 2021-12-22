defmodule Membrane.File.SourceTest do
  use ExUnit.Case
  use Mockery
  alias Membrane.File
  @module File.Source
  use File.TestSupport.Common
  alias File.CommonFile
  alias Membrane.Buffer

  def state(_ctx) do
    %{state: %{location: "", chunk_size: nil, fd: nil}}
  end

  setup_all :state

  describe "handle_demand buffers" do
    setup :inject_mock_fd

    test "should send chunk of size state.chunk_size", %{state: state} do
      state = %{state | chunk_size: 5}
      mock(CommonFile, [binread: 2], fn _file, 5 -> <<1, 2, 3, 4, 5>> end)

      assert {{:ok, buffer: {:output, %Buffer{payload: <<1, 2, 3, 4, 5>>}}, redemand: :output},
              ^state} = @module.handle_demand(:output, nil, :buffers, nil, state)
    end

    test "should send eos event on eof", %{state: state} do
      state = %{state | chunk_size: 5}
      mock(CommonFile, [binread: 2], :eof)

      assert {{:ok, end_of_stream: :output}, state} ==
               @module.handle_demand(:output, nil, :buffers, nil, state)
    end
  end

  describe "handle_demand bytes" do
    test "should send chunk of given size when demand in bytes", %{state: state} do
      mock(CommonFile, [binread: 2], fn _file, 5 -> <<1, 2, 3, 4, 5>> end)

      assert {{:ok, buffer: {:output, %Buffer{payload: <<1, 2, 3, 4, 5>>}}}, ^state} =
               @module.handle_demand(:output, 5, :bytes, nil, state)
    end

    test "should send eos event on eof", %{state: state} do
      mock(CommonFile, [binread: 2], :eof)

      assert {{:ok, end_of_stream: :output}, state} ==
               @module.handle_demand(:output, 5, :bytes, nil, state)
    end
  end
end
