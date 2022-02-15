defmodule Membrane.File.TestSupport.Boilerplate do
  @moduledoc false

  defmacro __using__(for: module) do
    quote do
      use ExUnit.Case
      use Patch

      alias Membrane.Buffer
      alias Membrane.File.CommonFile
      alias Membrane.Element.CallbackContext.{Prepare, Stop}

      @module unquote(module)

      defp inject_mock_fd(%{state: state}) do
        %{state: %{state | fd: :file}}
      end

      describe "common handle_stopped_to_prepared" do
        test "should open file", %{state: state} do
          %{location: location} = state

          patch(CommonFile, :open, fn ^location, _modes -> {:ok, :file} end)

          # as `File.Sink` uses also `:read` open mode, it needs to explicitly truncate the file if it already exists
          patch(CommonFile, :truncate, fn :file -> :ok end)

          assert {:ok, %{fd: :file}} = unquote(module).handle_stopped_to_prepared(%{}, state)
        end
      end

      describe "common handle_prepared_to_stopped" do
        setup :inject_mock_fd

        test "should close file", %{state: state} do
          %{fd: fd} = state

          patch(CommonFile, :close, fn ^fd -> :ok end)

          assert {:ok, %{fd: nil}} = unquote(module).handle_prepared_to_stopped(%{}, state)

          assert_called_once(CommonFile.close(^fd))
        end
      end
    end
  end
end
