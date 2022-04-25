defmodule Membrane.File.Sink do
  @moduledoc """
  Element that creates a file and stores incoming buffers there (in binary format).

  When `Membrane.File.SeekEvent` is received, the element starts writing buffers starting
  from `position`. By default, it overwrites previously stored bytes. You can set `insert?`
  field of the event to `true` to start inserting new buffers without overwriting previous ones.
  Please note, that inserting requires rewriting the file, what negatively impacts performance.
  For more information refer to `Membrane.File.SeekEvent` moduledoc.
  """
  use Membrane.Sink

  alias Membrane.File.SeekEvent

  @common_file Membrane.File.CommonFileBehaviour.get_impl()

  def_options location: [
                spec: Path.t(),
                description: "Path of the output file"
              ]

  def_input_pad :input, demand_unit: :buffers, caps: :any

  @impl true
  def handle_init(%__MODULE__{location: location}) do
    {:ok,
     %{
       location: Path.expand(location),
       temp_location: Path.expand(location <> ".tmp"),
       fd: nil,
       temp_fd: nil
     }}
  end

  @impl true
  def handle_stopped_to_prepared(_ctx, %{location: location} = state) do
    fd = @common_file.open!(location, [:read, :write])
    :ok = @common_file.truncate!(fd)
    {:ok, %{state | fd: fd}}
  end

  @impl true
  def handle_prepared_to_playing(_ctx, state) do
    {{:ok, demand: :input}, state}
  end

  @impl true
  def handle_write(:input, buffer, _ctx, %{fd: fd} = state) do
    :ok = @common_file.write!(fd, buffer)
    {{:ok, demand: :input}, state}
  end

  @impl true
  def handle_event(:input, %SeekEvent{insert?: insert?, position: position}, _ctx, state) do
    state =
      if insert? do
        split_file(state, position)
      else
        seek_file(state, position)
      end

    {:ok, state}
  end

  def handle_event(pad, event, ctx, state), do: super(pad, event, ctx, state)

  @impl true
  def handle_prepared_to_stopped(_ctx, %{fd: fd} = state) do
    state = maybe_merge_temporary(state)
    :ok = @common_file.close!(fd)
    {:ok, %{state | fd: nil}}
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

  defp maybe_merge_temporary(%{fd: fd, temp_fd: temp_fd} = state) do
    # TODO: Consider improving performance for multi-insertion scenarios by using
    # multiple temporary files and merging them only once on `handle_prepared_to_stopped/2`.
    _bytes_copied = @common_file.copy!(temp_fd, fd)
    remove_temporary(state)
  end

  defp open_temporary(%{temp_fd: nil, temp_location: temp_location} = state) do
    temp_fd = @common_file.open!(temp_location, [:read, :exclusive])
    %{state | temp_fd: temp_fd}
  end

  defp remove_temporary(%{temp_fd: temp_fd, temp_location: temp_location} = state) do
    :ok = @common_file.close!(temp_fd)
    :ok = @common_file.rm!(temp_location)
    %{state | temp_fd: nil}
  end
end
