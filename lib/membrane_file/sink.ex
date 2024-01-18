defmodule Membrane.File.Sink do
  @moduledoc """
  Element that creates a file and stores incoming buffers there (in binary format).
  Can also be used as a pipe to standard output by setting location to :stdout,
  though this requires additional configuration.

  When `Membrane.File.SeekSinkEvent` is received, the element starts writing buffers starting
  from `position`. By default, it overwrites previously stored bytes. You can set `insert?`
  field of the event to `true` to start inserting new buffers without overwriting previous ones.
  Please note, that inserting requires rewriting the file, what negatively impacts performance.
  For more information refer to `Membrane.File.SeekSinkEvent` moduledoc.

  Pipeline logs are directed to standard output by default. To separate them from the sink's output
  we recommend redirecting the logger to standard error. For simple use cases using the default logger
  configuration (like stand-alone scripts) this can be achieved by simply calling redirect_logs/1.
  See examples/file_to_pipe.exs for a working example.
  """
  use Membrane.Sink

  alias Membrane.File.SeekSinkEvent

  @common_file Membrane.File.CommonFileBehaviour.get_impl()

  def_options location: [
                spec: Path.t() | :stdout,
                description: "Path of the output file or :stdout"
              ]

  def_input_pad :input, flow_control: :manual, demand_unit: :buffers, accepted_format: _any

  @spec redirect_logs() :: :ok
  def redirect_logs() do
    {:ok, config} = :logger.get_handler_config(:default)
    :ok = :logger.remove_handler(:default)

    :ok =
      :logger.add_handler(
        :default,
        :logger_std_h,
        put_in(config, [:config, :type], :standard_error)
      )
  end

  @impl true
  def handle_init(_ctx, %__MODULE__{location: :stdout}) do
    {[],
     %{
       location: :stdout
     }}
  end

  @impl true
  def handle_init(_ctx, %__MODULE__{location: location}) do
    {[],
     %{
       location: Path.expand(location),
       temp_location: Path.expand(location <> ".tmp"),
       fd: nil,
       temp_fd: nil
     }}
  end

  @impl true
  def handle_setup(_ctx, %{location: :stdout} = state) do
    {[], state}
  end

  @impl true
  def handle_setup(_ctx, %{location: location} = state) do
    fd = @common_file.open!(location, [:read, :write])
    :ok = @common_file.truncate!(fd)

    {[], %{state | fd: fd}}
  end

  @impl true
  def handle_playing(_ctx, state) do
    {[demand: :input], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, %{location: :stdout} = state) do
    :ok = @common_file.write!(:stdio, buffer)
    {[demand: :input], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, %{fd: fd} = state) do
    :ok = @common_file.write!(fd, buffer)
    {[demand: :input], state}
  end

  @impl true
  def handle_event(:input, %SeekSinkEvent{}, _ctx, %{location: :stdout} = _state) do
    raise "Seek event not supported for :stdout sink"
  end

  @impl true
  def handle_event(:input, %SeekSinkEvent{insert?: insert?, position: position}, _ctx, state) do
    state =
      if insert?,
        do: split_file(state, position),
        else: seek_file(state, position)

    {[], state}
  end

  def handle_event(pad, event, ctx, state), do: super(pad, event, ctx, state)

  @impl true
  def handle_end_of_stream(:input, _ctx, %{location: :stdout} = state) do
    {[], state}
  end

  @impl true
  def handle_end_of_stream(:input, _ctx, state) do
    {[], do_merge_and_close(state)}
  end

  @impl true
  def handle_terminate_request(_ctx, %{location: :stdout} = state) do
    {[terminate: :normal], state}
  end

  @impl true
  def handle_terminate_request(_ctx, state) do
    {[terminate: :normal], do_merge_and_close(state)}
  end

  defp do_merge_and_close(%{fd: nil} = state), do: state

  defp do_merge_and_close(state) do
    state = maybe_merge_temporary(state)
    @common_file.close!(state.fd)

    %{state | fd: nil}
  end

  defp seek_file(%{fd: fd} = state, position) do
    state = maybe_merge_temporary(state)
    _position = @common_file.seek!(fd, position)
    state
  end

  defp split_file(%{fd: fd} = state, position) do
    state =
      state
      |> seek_file(position)
      |> open_temporary()

    :ok = @common_file.split!(fd, state.temp_fd)
    state
  end

  defp maybe_merge_temporary(%{temp_fd: nil} = state), do: state

  defp maybe_merge_temporary(%{fd: fd, temp_fd: temp_fd, temp_location: temp_location} = state) do
    # TODO: Consider improving performance for multi-insertion scenarios by using
    # multiple temporary files and merging them only once on `handle_terminate_request/2`.
    copy_and_remove_temporary(fd, temp_fd, temp_location)
    %{state | temp_fd: nil}
  end

  defp open_temporary(%{temp_fd: nil, temp_location: temp_location} = state) do
    temp_fd = @common_file.open!(temp_location, [:read, :exclusive])

    %{state | temp_fd: temp_fd}
  end

  defp copy_and_remove_temporary(fd, temp_fd, temp_location) do
    _bytes_copied = @common_file.copy!(temp_fd, fd)
    :ok = @common_file.close!(temp_fd)
    :ok = @common_file.rm!(temp_location)
  end
end
