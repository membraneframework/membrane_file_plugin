defmodule Membrane.File.SinkTest do
  use ExUnit.Case
  use Mockery
  use Membrane.File.TestSupport.Common, module: Membrane.File.Sink

  alias Membrane.Buffer
  alias Membrane.File.{CommonFile, SeekEvent}

  @module Membrane.File.Sink

  defp state(_ctx) do
    %{state: %{location: "file", temp_location: "file.tmp", fd: nil, temp_fd: nil}}
  end

  setup_all :state

  describe "on handle_write" do
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

  describe "on SeekEvent" do
    setup :inject_mock_fd

    test "should change file descriptor position", %{
      state: state
    } do
      %{fd: file} = state
      position = {:bof, 32}

      mock(CommonFile, [seek!: 2], 32)

      assert {:ok, %{state | fd: file, temp_fd: nil}} ==
               @module.handle_event(:input, %SeekEvent{position: position}, nil, state)

      assert_called(CommonFile, :seek!, [^file, ^position], 1)
    end

    test "should change file descriptor position and split file if insertion is enabled", %{
      state: state
    } do
      %{fd: file, temp_location: temp_location} = state
      position = {:bof, 32}

      mock(CommonFile, [open!: 2], :temporary)
      mock(CommonFile, [seek!: 2], 32)
      mock(CommonFile, [split!: 2], :ok)

      assert {:ok, %{state | fd: file, temp_fd: :temporary}} ==
               @module.handle_event(
                 :input,
                 %SeekEvent{position: position, insert?: true},
                 nil,
                 state
               )

      assert_called(CommonFile, :open!, [^temp_location, _modes], 1)
      assert_called(CommonFile, :seek!, [^file, ^position], 1)
      assert_called(CommonFile, :split!, [^file, :temporary], 1)
    end

    test "should write to main file if temporary descriptor is opened", %{state: state} do
      %{fd: file} = state
      state = %{state | temp_fd: :temporary}
      buffer = %Buffer{payload: <<1, 2, 3>>}

      mock(CommonFile, [write!: 2], :ok)

      assert {{:ok, demand: :input}, %{state | fd: file, temp_fd: :temporary}} ==
               @module.handle_write(:input, buffer, nil, state)

      assert_called(CommonFile, :write!, [^file, ^buffer], 1)
    end

    test "should merge, close and remove temporary file if temporary descriptor is opened", %{
      state: state
    } do
      %{fd: file, temp_location: temp_location} = state
      state = %{state | temp_fd: :temporary}
      position = {:bof, 32}

      mock(CommonFile, [copy!: 2], 0)
      mock(CommonFile, [close!: 1], :ok)
      mock(CommonFile, [rm!: 1], :ok)
      mock(CommonFile, [seek!: 2], 32)

      assert {:ok, %{state | fd: file, temp_fd: nil}} ==
               @module.handle_event(:input, %SeekEvent{position: position}, nil, state)

      assert_called(CommonFile, :copy!, [:temporary, ^file], 1)
      assert_called(CommonFile, :close!, [:temporary], 1)
      assert_called(CommonFile, :rm!, [^temp_location], 1)
      assert_called(CommonFile, :seek!, [^file, ^position], 1)
    end
  end

  describe "on handle_prepared_to_stopped" do
    setup :inject_mock_fd

    test "should close file", %{state: state} do
      %{fd: file} = state

      mock(CommonFile, [close!: 1], :ok)

      assert {:ok, %{state | fd: nil}} == @module.handle_prepared_to_stopped(nil, state)

      assert_called(CommonFile, :close!, [^file], 1)
    end

    test "should handle temporary file if temporary descriptor is opened", %{state: state} do
      %{fd: file, temp_location: temp_location} = state
      state = %{state | temp_fd: :temporary}

      mock(CommonFile, [copy!: 2], 0)
      mock(CommonFile, [close!: 1], :ok)
      mock(CommonFile, [rm!: 1], :ok)

      assert {:ok, %{state | fd: nil, temp_fd: nil}} ==
               @module.handle_prepared_to_stopped(nil, state)

      assert_called(CommonFile, :copy!, [:temporary, ^file], 1)
      assert_called(CommonFile, :close!, [:temporary], 1)
      assert_called(CommonFile, :rm!, [^temp_location], 1)
      assert_called(CommonFile, :close!, [^file], 1)
    end
  end
end
