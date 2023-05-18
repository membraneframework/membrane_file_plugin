defmodule Membrane.File.TestCaseTemplate do
  @moduledoc false
  use ExUnit.CaseTemplate

  using opts do
    module = opts[:module]

    quote do
      import Mox
      import Membrane.Testing.Assertions

      setup :verify_on_exit!

      describe "template: common callbacks" do
        test "on handle_setup should open a file", %{state: state, ctx: ctx} do
          %{location: location} = state

          Membrane.File.CommonMock
          |> expect(:open!, fn ^location, _modes -> :file end)
          # in case of opening with `:read` flag, truncating needs to be done explicitly
          |> stub(:truncate!, fn _fd -> :ok end)

          assert {[], %{fd: :file}} = unquote(module).handle_setup(ctx, state)
        end

        test "on handle_terminate_request should close the opened file", context do
          %{state: %{fd: file} = state, ctx: ctx} = inject_mock_fd(context)

          Membrane.File.CommonMock
          |> expect(:close!, fn ^file -> :ok end)

          assert {[terminate: :normal], %{fd: nil}} =
                   unquote(module).handle_terminate_request(ctx, state)
        end
      end

      defp inject_mock_fd(%{state: state, ctx: ctx}) do
        %{state: %{state | fd: :file}, ctx: ctx}
      end
    end
  end
end
