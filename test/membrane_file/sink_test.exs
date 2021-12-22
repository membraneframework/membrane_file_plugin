defmodule Membrane.File.SinkTest do
  use ExUnit.Case
  use Mockery
  use Membrane.File.TestSupport.Common, module: Membrane.File.Sink

  alias Membrane.Buffer
  alias Membrane.File.CommonFile

  @module Membrane.File.Sink

  defp state(_ctx) do
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
