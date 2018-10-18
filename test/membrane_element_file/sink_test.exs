defmodule Membrane.Element.File.SinkTest do
  use ExUnit.Case
  use Mockery
  alias Membrane.Element.File
  @module File.Sink
  use File.TestSupport.Common
  alias File.CommonFile
  alias Membrane.Buffer

  def state(_ctx) do
    %{state: %{location: "", fd: nil}}
  end

  setup_all :state

  describe "handle_write" do
    setup :file

    test "should write received chunk and request demand", %{state: state} do
      mock(CommonFile, [binwrite: 2], fn _file, _data -> :ok end)

      assert {{:ok, demand: :input}, state} ==
               @module.handle_write(:input, %Buffer{payload: <<1, 2, 3>>}, nil, state)

      assert_called(CommonFile, :binwrite, [_file, <<1, 2, 3>>], 1)
    end
  end
end
