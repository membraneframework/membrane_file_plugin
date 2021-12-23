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

  alias Membrane.File.{CommonFile, Error, SeekEvent}

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
    with {:ok, fd} <- mockable(CommonFile).open(location, [:read, :write]),
         :ok <- mockable(CommonFile).truncate(fd) do
      {:ok, %{state | fd: fd}}
    else
      error -> Error.wrap(error, :open, state)
    end
  end

  @impl true
  def handle_prepared_to_playing(_ctx, state) do
    {{:ok, demand: :input}, state}
  end

  @impl true
  def handle_write(:input, buffer, _ctx, %{fd: fd} = state) do
    case mockable(CommonFile).write(fd, buffer) do
      :ok -> {{:ok, demand: :input}, state}
      error -> Error.wrap(error, :write, state)
    end
  end

  @impl true
  def handle_event(:input, %SeekEvent{insert?: insert?, position: position}, _ctx, state) do
    if insert? do
      split_file(position, state)
    else
      seek_file(position, state)
    end
  end

  def handle_event(pad, event, ctx, state), do: super(pad, event, ctx, state)

  @impl true
  def handle_prepared_to_stopped(_ctx, %{fd: fd} = state) do
    with {:ok, state} <- maybe_merge_temporary(state),
         :ok <- mockable(CommonFile).close(fd) do
      {:ok, %{state | fd: nil}}
    else
      error -> Error.wrap(error, :close, state)
    end
  end

  defp seek_file(position, %{fd: fd} = state) do
    with {:ok, state} <- maybe_merge_temporary(state),
         {:ok, _position} <- mockable(CommonFile).seek(fd, position) do
      {:ok, state}
    else
      error -> Error.wrap(error, :seek_file, state)
    end
  end

  defp split_file(position, %{fd: fd} = state) do
    with {:ok, state} <- seek_file(position, state),
         {:ok, state} <- open_temporary(state),
         :ok <- mockable(CommonFile).split(fd, state.temp_fd) do
      {:ok, state}
    else
      error -> Error.wrap(error, :split_file, state)
    end
  end

  defp maybe_merge_temporary(%{temp_fd: nil} = state), do: {:ok, state}

  defp maybe_merge_temporary(%{fd: fd, temp_fd: temp_fd} = state) do
    # TODO: Consider improving performance for multi-insertion scenarios by using
    # multiple temporary files and merging them only once on `handle_prepared_to_stopped/2`.
    with {:ok, _bytes_copied} <- mockable(CommonFile).copy(temp_fd, fd),
         {:ok, state} <- remove_temporary(state) do
      {:ok, state}
    else
      error -> Error.wrap(error, :merge_temporary, state)
    end
  end

  defp open_temporary(%{temp_fd: nil, temp_location: temp_location} = state) do
    case mockable(CommonFile).open(temp_location, [:read, :exclusive]) do
      {:ok, temp_fd} -> {:ok, %{state | temp_fd: temp_fd}}
      error -> Error.wrap(error, :open_temporary, state)
    end
  end

  defp remove_temporary(%{temp_fd: temp_fd, temp_location: temp_location} = state) do
    with :ok <- mockable(CommonFile).close(temp_fd),
         :ok <- mockable(CommonFile).rm(temp_location) do
      {:ok, %{state | temp_fd: nil}}
    else
      error -> Error.wrap(error, :remove_temporary, state)
    end
  end
end
