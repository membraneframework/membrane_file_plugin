defmodule Membrane.File.TestCaseTemplate do
  @moduledoc false
  use ExUnit.CaseTemplate

  using opts do
    module = opts[:module]

    quote do
      import Mox

      alias Membrane.File.CommonMock
      alias Membrane.Element.CallbackContext.{Prepare, Stop}

      setup :verify_on_exit!

      describe "template: handle_setup" do
        test "should open file", %{state: state, ctx: ctx} do
          %{location: location} = state

          CommonMock
          |> expect(:open!, fn ^location, _modes -> :file end)
          # in case of opening with `:read` flag, truncating needs to be done explicitly
          |> stub(:truncate!, fn _fd -> :ok end)

          assert {[], %{fd: :file}} = unquote(module).handle_setup(ctx, state)

        end
      end

      # describe "template: handle_prepared_to_stopped" do
      #   setup :inject_mock_fd

      #   test "should close file", %{state: state} do
      #     %{fd: fd} = state

      #     CommonMock
      #     |> expect(:close!, fn _fd -> :ok end)

      #     assert {[], %{fd: nil}} = unquote(module).handle_prepared_to_stopped(%{}, state)
      #   end
      # end

      defp inject_mock_fd(%{state: state, ctx: ctx}) do
        %{state: %{state | fd: :file}, ctx: ctx}
      end
    end
  end
end
