# defmodule Mix.Shell.Ultraquiet do
#   @behaviour Mix.Shell

#   def print_app, do: :ok

#   def error(_message), do: :ok

#   def info(_message), do: :ok

#   def print_app(_message), do: :ok

#   def prompt(_message), do: :ok

#   def yes?(_message, _opts \\ []), do: :ok

#   def cmd(command, opts \\ []) do
#     Mix.Shell.cmd(command, opts, fn data -> data end)
#   end
# end

# {:ok, config} = :logger.get_handler_config(:default)
# config_dev = put_in(config, [:config, :type], :standard_error)

# :ok =
#   :logger.set_handler_config(:default, put_in(config, [:config, :type], :standard_error))

# :logger.remove_handler(:default)
# :ok =
#   :logger.add_handler(:default, :logger_std_h, put_in(config, [:config, :type], :standard_error))

# Logger.configure(device: :standard_error)
# Logger.Backends.Internal.configure(device: :standard_error)

Mix.start()
Mix.shell(Mix.Shell.Quiet)

Mix.install(
  [
    {:membrane_file_plugin, path: "."}
  ]
  # force: true
)

defmodule FileExamplePipeline do
  @doc """
  Example pipeline that reads its source code file and outputs it to /tmp/test.
  """

  use Membrane.Pipeline

  @doc false
  @impl true
  def handle_init(_ctx, %{target: target, input: input}) do
    spec =
      child(%Membrane.File.Source{location: input})
      |> child(:sink, %Membrane.File.Sink{location: :stdout})

    {[spec: spec], %{target: target}}
  end

  @impl true
  def handle_element_end_of_stream(:sink, :input, _ctx, state) do
    send(state.target, :done)
    {[], state}
  end
end

# # redirect membrane logs to stderr
Membrane.File.Sink.redirect_logs()

[input] = System.argv()

{:ok, _supervisor, pid} =
  Membrane.Pipeline.start_link(FileExamplePipeline, %{input: input, target: self()})

receive do
  :done -> Membrane.Pipeline.terminate(pid)
end
