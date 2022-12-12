defmodule Membrane.File.Sink.MultiTest do
  use Membrane.File.TestCaseTemplate, module: Membrane.File.Sink.Multi, async: true

  alias Membrane.Buffer
  alias Membrane.File.{CommonMock, SplitEvent}

  @module Membrane.File.Sink.Multi

  defp state_and_ctx(_ctx) do
    %{
      ctx: nil,
      state: %{
        location: "",
        fd: nil,
        naming_fun: fn _index -> "" end,
        split_on: SplitEvent,
        index: 0
      }
    }
  end

  setup :state_and_ctx

  describe "handle_write" do
    setup :inject_mock_fd

    test "should write received chunk and request demand", %{state: state} do
      %{fd: file} = state
      buffer = %Buffer{payload: <<1, 2, 3>>}

      CommonMock |> expect(:write!, fn ^file, ^buffer -> :ok end)

      assert {[demand: :input], state} ==
               @module.handle_write(:input, buffer, nil, state)
    end
  end

  describe "handle_event" do
    setup :inject_mock_fd

    setup %{state: state, ctx: ctx} do
      %{state: %{state | naming_fun: &Integer.to_string/1}, ctx: ctx}
    end

    test "should close current file and open new one if event type is state.split_on", %{
      state: state,
      ctx: ctx
    } do
      %{fd: file} = state

      CommonMock
      |> expect(:close!, fn ^file -> :ok end)
      |> expect(:open!, fn "1", _modes -> :new_file end)

      assert {[], %{state | index: 1, fd: :new_file}} ==
               @module.handle_event(:input, %SplitEvent{}, ctx, state)
    end

    test "should not close current file and open new one if event type is not state.split_on", %{
      state: state,
      ctx: ctx
    } do
      %{fd: file} = state

      assert {[], %{state | index: 0, fd: file}} ==
               @module.handle_event(:input, :whatever, ctx, state)
    end
  end
end
