defmodule Membrane.File.SinkTest do
  use Membrane.File.TestCaseTemplate, module: Membrane.File.Sink, async: true

  alias Membrane.Buffer
  alias Membrane.File.{CommonMock, SeekEvent}

  @module Membrane.File.Sink

  defp state_and_ctx(_ctx) do
    {:ok, resource_guard} = Membrane.ResourceGuard.start_link(self())

    %{
      ctx: %{resource_guard: resource_guard},
      state: %{location: "file", temp_location: "file.tmp", fd: nil, temp_fd: nil}
    }
  end

  setup :state_and_ctx

  setup :verify_on_exit!

  describe "on handle_write" do
    setup :inject_mock_fd

    test "should write received chunk and request demand", %{state: state, ctx: ctx} do
      %{fd: file} = state
      buffer = %Buffer{payload: <<1, 2, 3>>}

      CommonMock |> expect(:write!, fn ^file, ^buffer -> :ok end)

      assert {[demand: :input], state} ==
               @module.handle_write(:input, buffer, ctx, state)
    end
  end

  describe "on SeekEvent" do
    setup :inject_mock_fd

    test "should change file descriptor position", %{
      state: state,
      ctx: ctx
    } do
      %{fd: file} = state
      position = {:bof, 32}

      CommonMock |> expect(:seek!, fn ^file, ^position -> 32 end)

      assert {[], %{state | fd: file, temp_fd: nil}} ==
               @module.handle_event(:input, %SeekEvent{position: position}, ctx, state)
    end

    test "should change file descriptor position and split file if insertion is enabled", %{
      state: state,
      ctx: ctx
    } do
      %{fd: file, temp_location: temp_location} = state
      position = {:bof, 32}

      CommonMock
      |> expect(:open!, fn ^temp_location, _modes -> :temporary end)
      |> expect(:seek!, fn ^file, ^position -> 32 end)
      |> expect(:split!, fn ^file, :temporary -> :ok end)

      assert {[], %{state | fd: file, temp_fd: :temporary}} ==
               @module.handle_event(
                 :input,
                 %SeekEvent{position: position, insert?: true},
                 ctx,
                 state
               )
    end

    test "should write to main file if temporary descriptor is opened", %{state: state, ctx: ctx} do
      %{fd: file} = state
      state = %{state | temp_fd: :temporary}
      buffer = %Buffer{payload: <<1, 2, 3>>}

      CommonMock |> expect(:write!, fn ^file, ^buffer -> :ok end)

      assert {[demand: :input], %{state | fd: file, temp_fd: :temporary}} ==
               @module.handle_write(:input, buffer, ctx, state)
    end

    test "should merge, close and remove temporary file if temporary descriptor is opened", %{
      state: state,
      ctx: ctx
    } do
      %{fd: file, temp_location: temp_location} = state
      state = %{state | temp_fd: :temporary}
      position = {:bof, 32}

      CommonMock
      |> expect(:copy!, fn :temporary, ^file -> 0 end)
      |> expect(:close!, fn :temporary -> :ok end)
      |> expect(:rm!, fn ^temp_location -> :ok end)
      |> expect(:seek!, fn ^file, ^position -> 32 end)

      assert {[], %{state | fd: file, temp_fd: nil}} ==
               @module.handle_event(:input, %SeekEvent{position: position}, ctx, state)
    end
  end

  describe "on handle_prepared_to_stopped" do
    setup :inject_mock_fd

    # test "should close file", %{state: state} do
    #   %{fd: file} = state

    #   CommonMock |> expect(:close!, fn ^file -> :ok end)

    #   assert {[], %{state | fd: nil}} == @module.handle_prepared_to_stopped(nil, state)
    # end

    # test "should handle temporary file if temporary descriptor is opened", %{state: state} do
    #   %{fd: file, temp_location: temp_location} = state
    #   state = %{state | temp_fd: :temporary}

    #   CommonMock
    #   |> expect(:copy!, fn :temporary, ^file -> 0 end)
    #   |> expect(:close!, fn :temporary -> :ok end)
    #   |> expect(:rm!, fn ^temp_location -> :ok end)
    #   |> expect(:close!, fn ^file -> :ok end)

    #   assert {[], %{state | fd: nil, temp_fd: nil}} ==
    #            @module.handle_prepared_to_stopped(nil, state)
    # end
  end
end
