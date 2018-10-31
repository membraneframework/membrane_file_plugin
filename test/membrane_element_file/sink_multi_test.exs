defmodule Membrane.Element.File.Sink.MultiTest do
  use ExUnit.Case
  use Mockery
  alias Membrane.Element.File
  alias File.{CommonFile, SplitEvent}
  alias Membrane.Buffer
  @module File.Sink.Multi
  use File.TestSupport.Common

  def state(_ctx) do
    %{
      state: %{
        location: "",
        fd: nil,
        naming_fun: fn _ -> "" end,
        split_on: SplitEvent,
        index: 0
      }
    }
  end

  setup_all :state

  describe "handle_write" do
    setup :file

    test "should write received chunk and request demand", %{state: state} do
      %{fd: file} = state
      mock(CommonFile, [binwrite: 2], :ok)

      assert {{:ok, demand: :input}, state} ==
               @module.handle_write(:input, %Buffer{payload: <<1, 2, 3>>}, nil, state)

      assert_called(CommonFile, :binwrite, [^file, <<1, 2, 3>>], 1)
    end
  end

  describe "handle_event" do
    setup :file

    setup %{state: state} do
      %{state: %{state | naming_fun: fn x -> "#{x}" end}}
    end

    test "should close current file and open new one if event type is state.split_on", %{
      state: state
    } do
      mock(CommonFile, [close: 1], fn state -> {:ok, %{state | fd: nil}} end)
      mock(CommonFile, [open: 3], fn "1", _mode, state -> {:ok, %{state | fd: :new_file}} end)

      assert {:ok, %{state | index: 1, fd: :new_file}} ==
               @module.handle_event(:input, %SplitEvent{}, nil, state)

      assert_called(CommonFile, :close, [^state], 1)
      assert_called(CommonFile, :open, ["1", _mode, _state], 1)
    end

    test "should not close current file and open new one if event type is not state.split_on", %{
      state: state
    } do
      mock(CommonFile, [close: 1], fn state -> {:ok, %{state | fd: nil}} end)
      mock(CommonFile, [open: 3], fn "1", _mode, state -> {:ok, %{state | fd: :new_file}} end)

      assert {:ok, %{state | index: 0, fd: :file}} ==
               @module.handle_event(:input, :whatever, nil, state)
    end
  end

  describe "handle_prepared_to_stopped" do
    setup :file

    test "should increment file index", %{state: state} do
      mock(CommonFile, [close: 1], fn state -> {:ok, %{state | fd: nil}} end)
      assert {:ok, %{index: 1}} = @module.handle_prepared_to_stopped(%{}, state)
    end
  end
end
