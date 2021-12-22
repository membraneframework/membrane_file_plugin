defmodule Membrane.File.SinkTest do
  use ExUnit.Case
  use Mockery
  alias Membrane.File
  @module File.Sink
  use File.TestSupport.Common
  alias File.CommonFile
  alias Membrane.Buffer

  def state(_ctx) do
    %{state: %{location: "", fd: nil, temp_fd: nil}}
  end

  setup_all :state

  describe "handle_write" do
    setup :inject_mock_fd

    test "should write received chunk and request demand", %{state: state} do
      %{fd: file} = state

      mock(CommonFile, [write: 2], :ok)
      buffer = %Buffer{payload: <<1, 2, 3>>}

      assert {{:ok, demand: :input}, state} ==
               @module.handle_write(:input, buffer, nil, state)

      assert_called(CommonFile, :write, [^file, ^buffer], 1)
    end
  end
end
