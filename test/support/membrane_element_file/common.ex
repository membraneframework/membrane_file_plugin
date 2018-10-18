defmodule Membrane.Element.File.TestSupport.Common do
  defmacro __using__(_) do
    quote do
      alias Membrane.Element.File.CommonFile
      alias Membrane.Element.CallbackContext.{Prepare, Stop}

      describe "common handle_stopped_to_prepared" do
        test "should open file", %{state: state} do
          %{location: location} = state

          mock(CommonFile, [open: 3], fn ^location, _mode, state ->
            {:ok, %{state | fd: location}}
          end)

          mock(CommonFile, [open: 2], fn _mode, state -> {:ok, %{state | fd: state.location}} end)
          assert {:ok, %{fd: ^location}} = @module.handle_stopped_to_prepared(%{}, state)
        end
      end

      describe "common handle_prepared_to_stopped" do
        setup :file

        test "should close file", %{state: state} do
          %{fd: fd} = state
          mock(CommonFile, [close: 1], fn state -> {:ok, %{state | fd: nil}} end)
          assert {:ok, %{fd: nil}} = @module.handle_prepared_to_stopped(%{}, state)
          assert_called(CommonFile, :close, [%{fd: ^fd}], 1)
        end
      end

      def file(%{state: state}) do
        %{state: %{state | fd: :file}}
      end
    end
  end
end
