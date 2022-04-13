defmodule Membrane.File.Sink.MultiTest do
  use ExUnit.Case
  use Mockery
  use Membrane.File.TestSupport.Common, module: Membrane.File.Sink.Multi

  alias Membrane.File.{CommonFile, SplitEvent}
  alias Membrane.Buffer

  @module Membrane.File.Sink.Multi

  defp state(_ctx) do
    %{
      state: %{
        location: "",
        fd: nil,
        naming_fun: fn _index -> "" end,
        split_on: SplitEvent,
        index: 0
      }
    }
  end

  setup_all :state

  describe "handle_write" do
    setup :inject_mock_fd

    test "should write received chunk and request demand", %{state: state} do
      %{fd: file} = state

      mock(CommonFile, [write!: 2], :ok)
      buffer = %Buffer{payload: <<1, 2, 3>>}

      assert {{:ok, demand: :input}, state} ==
               @module.handle_write(:input, buffer, nil, state)

      assert_called(CommonFile, :write!, [^file, ^buffer], 1)
    end
  end

  describe "handle_event" do
    setup :inject_mock_fd

    setup %{state: state} do
      %{state: %{state | naming_fun: &Integer.to_string/1}}
    end

    test "should close current file and open new one if event type is state.split_on", %{
      state: state
    } do
      %{fd: file} = state

      mock(CommonFile, [close!: 1], :ok)
      mock(CommonFile, [open!: 2], fn "1", _modes -> :new_file end)

      assert {:ok, %{state | index: 1, fd: :new_file}} ==
               @module.handle_event(:input, %SplitEvent{}, nil, state)

      assert_called(CommonFile, :close!, [^file], 1)
      assert_called(CommonFile, :open!, ["1", _modes], 1)
    end

    test "should not close current file and open new one if event type is not state.split_on", %{
      state: state
    } do
      %{fd: file} = state

      mock(CommonFile, [close!: 1], :ok)
      mock(CommonFile, [open!: 2], fn "1", _modes -> {:ok, :new_file} end)

      assert {:ok, %{state | index: 0, fd: file}} ==
               @module.handle_event(:input, :whatever, nil, state)
    end
  end

  describe "handle_prepared_to_stopped" do
    test "should increment file index", %{state: state} do
      mock(CommonFile, [close!: 1], :ok)
      assert {:ok, %{index: 1, fd: nil}} = @module.handle_prepared_to_stopped(%{}, state)
    end
  end
end
