defmodule Membrane.File.TestCaseTemplate do
  @moduledoc false
  use ExUnit.CaseTemplate

  using opts do
    module = opts[:module]

    quote do
      import Mox
      import Membrane.Testing.Assertions

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

          assert_resource_guard_register(ctx.resource_guard, cleanup_function, _tag)

          CommonMock
          |> expect(:close!, fn :file -> :ok end)

          cleanup_function.()
        end
      end

      defp inject_mock_fd(%{state: state, ctx: ctx}) do
        %{state: %{state | fd: :file}, ctx: ctx}
      end
    end
  end
end
