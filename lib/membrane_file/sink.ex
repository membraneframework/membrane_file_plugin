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
  import Mockery.Macro

  alias Membrane.File.{CommonFile, SeekEvent}

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
    fd = mockable(CommonFile).open!(location, [:read, :write])
    :ok = mockable(CommonFile).truncate!(fd)
    {:ok, %{state | fd: fd}}
  end

  @impl true
  def handle_prepared_to_playing(_ctx, state) do
    {{:ok, demand: :input}, state}
  end

  @impl true
  def handle_write(:input, buffer, _ctx, %{fd: fd} = state) do
    :ok = mockable(CommonFile).write!(fd, buffer)
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
    :ok = mockable(CommonFile).close!(fd)
    {:ok, %{state | fd: nil}}
  end

  defp seek_file(%{fd: fd} = state, position) do
    state = maybe_merge_temporary(state)
    _position = mockable(CommonFile).seek!(fd, position)
    state
  end

  defp split_file(%{fd: fd} = state, position) do
    state =
      state
      |> seek_file(position)
      |> open_temporary()

    :ok = mockable(CommonFile).split!(fd, state.temp_fd)
    state
  end

  defp maybe_merge_temporary(%{temp_fd: nil} = state), do: state

  defp maybe_merge_temporary(%{fd: fd, temp_fd: temp_fd} = state) do
    # TODO: Consider improving performance for multi-insertion scenarios by using
    # multiple temporary files and merging them only once on `handle_prepared_to_stopped/2`.
    _bytes_copied = mockable(CommonFile).copy!(temp_fd, fd)
    remove_temporary(state)
  end

  defp open_temporary(%{temp_fd: nil, temp_location: temp_location} = state) do
    temp_fd = mockable(CommonFile).open!(temp_location, [:read, :exclusive])
    %{state | temp_fd: temp_fd}
  end

  defp remove_temporary(%{temp_fd: temp_fd, temp_location: temp_location} = state) do
    :ok = mockable(CommonFile).close!(temp_fd)
    :ok = mockable(CommonFile).rm!(temp_location)
    %{state | temp_fd: nil}
  end
end
