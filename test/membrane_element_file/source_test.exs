defmodule Membrane.Element.File.SourceTest do
  use ExUnit.Case
  use Mockery
  alias Membrane.Element.File
  @module File.Source
  use File.TestSupport.Common
  alias File.CommonFile
  alias Membrane.{Buffer, Event}

  def state(_ctx) do
    %{state: %{location: "", chunk_size: nil, fd: nil}}
  end

  setup_all :state

  describe "handle_demand1" do
    setup :file

    test "should send chunk of size state.chunk_size", %{state: state} do
      state = %{state | chunk_size: 5}
      mock(CommonFile, [binread: 2], fn _file, 5 -> <<1, 2, 3, 4, 5>> end)

      assert {{:ok, buffer: {:source, %Buffer{payload: <<1, 2, 3, 4, 5>>}}}, ^state} =
               @module.handle_demand1(:source, nil, state)
    end

    test "should send eos event on eof", %{state: state} do
      state = %{state | chunk_size: 5}
      mock(CommonFile, [binread: 2], :eof)

      assert {{:ok, event: {:source, Event.eos()}}, state} ==
               @module.handle_demand1(:source, nil, state)
    end
  end

  describe "handle_demand" do
    setup :file

    test "should send chunk of given size when demand in bytes", %{state: state} do
      mock(CommonFile, [binread: 2], fn _file, 5 -> <<1, 2, 3, 4, 5>> end)

      assert {{:ok, buffer: {:source, %Buffer{payload: <<1, 2, 3, 4, 5>>}}}, ^state} =
               @module.handle_demand(:source, 5, :bytes, nil, state)
    end

    test "should send eos event on eof", %{state: state} do
      mock(CommonFile, [binread: 2], :eof)

      assert {{:ok, event: {:source, Event.eos()}}, state} ==
               @module.handle_demand(:source, 5, :bytes, nil, state)
    end
  end
end
