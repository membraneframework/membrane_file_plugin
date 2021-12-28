defmodule Membrane.File.TestSupport.Common do
  @moduledoc false

  defmacro __using__(module: module) do
    quote do
      alias Membrane.File.CommonFile
      alias Membrane.Element.CallbackContext.{Prepare, Stop}

      describe "common handle_stopped_to_prepared" do
        test "should open file", %{state: state} do
          %{location: location} = state

          mock(CommonFile, [open: 2], fn ^location, _modes -> {:ok, :file} end)

          # in case of opening with `:read` flag, truncating needs to be done explicitly
          mock(CommonFile, [truncate: 1], :ok)

          assert {:ok, %{fd: :file}} = unquote(module).handle_stopped_to_prepared(%{}, state)
        end
      end

      describe "common handle_prepared_to_stopped" do
        setup :inject_mock_fd

        test "should close file", %{state: state} do
          %{fd: fd} = state

          mock(CommonFile, [close: 1], :ok)

          assert {:ok, %{fd: nil}} = unquote(module).handle_prepared_to_stopped(%{}, state)

          assert_called(CommonFile, :close, [^fd], 1)
        end
      end

      defp inject_mock_fd(%{state: state}) do
        %{state: %{state | fd: :file}}
      end
    end
  end
end
