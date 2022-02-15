defmodule Membrane.File.SinkTest do
  use Membrane.File.TestSupport.Boilerplate, for: Membrane.File.Sink

  alias Membrane.File.SeekEvent

  defp state(_ctx) do
    %{state: %{location: "file", temp_location: "file.tmp", fd: nil, temp_fd: nil}}
  end

  setup_all [:state, :inject_mock_fd]

  describe "on handle_write" do
    test "should write received chunk and request demand", %{state: state} do
      %{fd: file} = state
      buffer = %Buffer{payload: <<1, 2, 3>>}

      patch(CommonFile, :write, :ok)

      assert {{:ok, demand: :input}, state} ==
               @module.handle_write(:input, buffer, nil, state)

      assert_called_once(CommonFile.write(^file, ^buffer))
    end
  end

  describe "on SeekEvent" do
    test "should change file descriptor position", %{
      state: state
    } do
      %{fd: file} = state
      position = {:bof, 32}

      patch(CommonFile, :seek, {:ok, 32})

      assert {:ok, %{state | fd: file, temp_fd: nil}} ==
               @module.handle_event(:input, %SeekEvent{position: position}, nil, state)

      assert_called_once(CommonFile.seek(^file, ^position))
    end

    test "should change file descriptor position and split file if insertion is enabled", %{
      state: state
    } do
      %{fd: file, temp_location: temp_location} = state
      position = {:bof, 32}

      patch(CommonFile, :open, {:ok, :temporary})
      patch(CommonFile, :seek, {:ok, 32})
      patch(CommonFile, :split, :ok)

      assert {:ok, %{state | fd: file, temp_fd: :temporary}} ==
               @module.handle_event(
                 :input,
                 %SeekEvent{position: position, insert?: true},
                 nil,
                 state
               )

      assert_called_once(CommonFile.open(^temp_location, _modes))
      assert_called_once(CommonFile.seek(^file, position))
      assert_called_once(CommonFile.split(^file, :temporary))
    end

    test "should write to main file if temporary descriptor is opened", %{state: state} do
      %{fd: file} = state
      state = %{state | temp_fd: :temporary}
      buffer = %Buffer{payload: <<1, 2, 3>>}

      patch(CommonFile, :write, :ok)

      assert {{:ok, demand: :input}, %{state | fd: file, temp_fd: :temporary}} ==
               @module.handle_write(:input, buffer, nil, state)

      assert_called_once(CommonFile.write(^file, ^buffer))
    end

    test "should merge, close and remove temporary file if temporary descriptor is opened", %{
      state: state
    } do
      %{fd: file, temp_location: temp_location} = state

      temp_file = :temporary
      position = {:bof, 32}
      state = %{state | temp_fd: temp_file}

      patch(CommonFile, :copy, {:ok, 0})
      patch(CommonFile, :close, :ok)
      patch(CommonFile, :rm, :ok)
      patch(CommonFile, :seek, {:ok, 32})

      assert {:ok, %{state | fd: file, temp_fd: nil}} ==
               @module.handle_event(:input, %SeekEvent{position: position}, nil, state)

      assert_called_once(CommonFile.copy(^temp_file, ^file))
      assert_called_once(CommonFile.close(^temp_file))
      assert_called_once(CommonFile.rm(^temp_location))
      assert_called_once(CommonFile.seek(^file, ^position))
    end
  end

  describe "on handle_prepared_to_stopped" do
    test "should handle temporary file if temporary descriptor is opened", %{state: state} do
      %{fd: file, temp_location: temp_location} = state

      temp_file = :temporary
      state = %{state | temp_fd: temp_file}

      patch(CommonFile, :copy, {:ok, 0})
      patch(CommonFile, :close, :ok)
      patch(CommonFile, :rm, :ok)

      assert {:ok, %{state | fd: nil, temp_fd: nil}} ==
               @module.handle_prepared_to_stopped(nil, state)

      assert_called_once(CommonFile.copy(^temp_file, ^file))
      assert_called_once(CommonFile.close(^temp_file))
      assert_called_once(CommonFile.rm(^temp_location))
      assert_called_once(CommonFile.close(^file))
    end
  end
end
