defmodule Membrane.Element.File.Sink.MultiTest do
  use ExUnit.Case
  use Mockery
  alias Membrane.Element.File
  @module File.Sink.Multi
  use File.TestSupport.Common
  alias File.CommonFile
  alias Membrane.{Buffer, Event}

  def state(_ctx) do
    %{state: %{location: "", fd: nil, naming_fun: fn _ -> "" end, split_on: :split, index: 0}}
  end

  def file(%{state: state}) do
    %{state: %{state | fd: :file}}
  end

  describe "handle_write1" do
    setup [:state, :file]

    test "should write received chunk and request demand", %{state: state} do
      %{fd: file} = state
      mock(CommonFile, [binwrite: 2], :ok)

      assert {{:ok, demand: :sink}, state} ==
               @module.handle_write1(:sink, %Buffer{payload: <<1, 2, 3>>}, nil, state)

      assert_called(CommonFile, :binwrite, [^file, <<1, 2, 3>>], 1)
    end
  end

  describe "handle_event" do
    setup [:state, :file]

    setup %{state: state} do
      %{state: %{state | naming_fun: fn x -> "#{x}" end}}
    end

    test "should close current file and open new one if type is state.split_on", %{state: state} do
      mock(CommonFile, [close: 1], fn state -> {:ok, %{state | fd: nil}} end)
      mock(CommonFile, [open: 3], fn "1", _mode, state -> {:ok, %{state | fd: :new_file}} end)

      assert {:ok, %{state | index: 1, fd: :new_file}} ==
               @module.handle_event(:sink, %Event{type: :split}, nil, state)

      assert_called(CommonFile, :close, [^state], 1)
      assert_called(CommonFile, :open, ["1", _mode, _state], 1)
    end
  end
end
