defmodule Membrane.Element.File.TestSupport.Common do
  defmacro __using__(_) do
    quote do
      alias Membrane.Element.File.CommonFile

      describe "handle_prepare" do
        setup :state

        test "should open file", %{state: state} do
          %{location: location} = state

          mock(CommonFile, [open: 3], fn ^location, _mode, state ->
            {:ok, %{state | fd: location}}
          end)

          mock(CommonFile, [open: 2], fn _mode, state -> {:ok, %{state | fd: state.location}} end)
          assert {:ok, %{state | fd: location}} == @module.handle_prepare(:stopped, state)
        end
      end

      describe "handle_stop" do
        setup [:state, :file]

        test "should close file", %{state: state} do
          %{fd: fd} = state
          mock(CommonFile, [close: 1], fn state -> {:ok, %{state | fd: nil}} end)
          assert {:ok, %{state | fd: nil}} == @module.handle_stop(state)
          assert_called(CommonFile, :close, [%{fd: ^fd}], 1)
        end
      end
    end
  end
end
