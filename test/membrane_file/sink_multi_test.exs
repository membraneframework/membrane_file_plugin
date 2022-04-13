defmodule Membrane.File.Sink.MultiTest do
  use Membrane.File.TestCaseTemplate, module: Membrane.File.Sink.Multi, async: true

  alias Membrane.File.{CommonMock, SplitEvent}
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

  setup :verify_on_exit!

  describe "handle_write" do
    setup :inject_mock_fd

    test "should write received chunk and request demand", %{state: state} do
      %{fd: file} = state
      buffer = %Buffer{payload: <<1, 2, 3>>}

      CommonMock |> expect(:write!, fn ^file, ^buffer -> :ok end)

      assert {{:ok, demand: :input}, state} ==
               @module.handle_write(:input, buffer, nil, state)
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

      CommonMock
      |> expect(:close!, fn ^file -> :ok end)
      |> expect(:open!, fn "1", _modes -> :new_file end)

      assert {:ok, %{state | index: 1, fd: :new_file}} ==
               @module.handle_event(:input, %SplitEvent{}, nil, state)
    end

    test "should not close current file and open new one if event type is not state.split_on", %{
      state: state
    } do
      %{fd: file} = state

      assert {:ok, %{state | index: 0, fd: file}} ==
               @module.handle_event(:input, :whatever, nil, state)
    end
  end

  describe "handle_prepared_to_stopped" do
    test "should increment file index", %{state: state} do
      CommonMock |> expect(:close!, fn _fd -> :ok end)
      assert {:ok, %{index: 1, fd: nil}} = @module.handle_prepared_to_stopped(%{}, state)
    end
  end
end
