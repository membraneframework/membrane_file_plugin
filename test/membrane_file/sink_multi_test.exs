defmodule Membrane.File.Sink.MultiTest do
  use Membrane.File.TestSupport.Boilerplate, for: Membrane.File.Sink.Multi

  alias Membrane.File.SplitEvent

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

  setup_all [:state, :inject_mock_fd]

  describe "handle_write" do
    test "should write received chunk and request demand", %{state: state} do
      %{fd: file} = state
      buffer = %Buffer{payload: <<1, 2, 3>>}

      patch(CommonFile, :write, :ok)

      assert {{:ok, demand: :input}, state} ==
               @module.handle_write(:input, buffer, nil, state)

      assert_called_once(CommonFile.write(^file, ^buffer))
    end
  end

  describe "handle_event" do
    setup %{state: state} do
      %{state: %{state | naming_fun: &Integer.to_string/1}}
    end

    test "should close current file and open new one if event type is state.split_on", %{
      state: state
    } do
      %{fd: file} = state

      patch(CommonFile, :close, :ok)
      patch(CommonFile, :open, {:ok, :new_file})

      assert {:ok, %{state | index: 1, fd: :new_file}} ==
               @module.handle_event(:input, %SplitEvent{}, nil, state)

      assert_called_once(CommonFile.close(^file))
      assert_called_once(CommonFile.open("1", _modes))
    end

    test "should not close current file and open new one if event type is not state.split_on", %{
      state: state
    } do
      %{fd: file} = state

      patch(CommonFile, :close, :ok)
      patch(CommonFile, :open, {:ok, :new_file})

      assert {:ok, %{state | index: 0, fd: file}} ==
               @module.handle_event(:input, :whatever, nil, state)

      refute_any_call(CommonFile, :close)
      refute_any_call(CommonFile, :open)
    end
  end

  describe "handle_prepared_to_stopped" do
    test "should increment file index", %{state: state} do
      %{fd: file} = state

      patch(CommonFile, :close, :ok)

      assert {:ok, %{index: 1, fd: nil}} = @module.handle_prepared_to_stopped(%{}, state)

      assert_called_once(CommonFile.close(^file))
    end
  end
end
