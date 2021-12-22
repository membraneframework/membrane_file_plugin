defmodule Membrane.File.Sink do
  @moduledoc """
  Element that creates a file and stores incoming buffers there (in binary format).
  """
  use Membrane.Sink
  import Mockery.Macro

  alias Membrane.File.{CommonFile, Error, SeekEvent}

  def_options location: [
                spec: String.t(),
                description: "Path to the file"
              ]

  def_input_pad :input, demand_unit: :buffers, caps: :any

  @impl true
  def handle_init(%__MODULE__{location: location}) do
    {:ok,
     %{
       location: location,
       temp_location: location <> ".tmp",
       fd: nil,
       temp_fd: nil
     }}
  end

  @impl true
  def handle_stopped_to_prepared(_ctx, %{location: location} = state) do
    case mockable(CommonFile).open(location, [:read, :write]) do
      {:ok, fd} -> {:ok, %{state | fd: fd}}
      error -> Error.wrap_error(error, :open, state)
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
      error -> Error.wrap_error(error, :write, state)
    end
  end

  @impl true
  def handle_event(:input, %SeekEvent{insert?: insert?, position: position}, _ctx, state) do
    if insert?, do: split_file(position, state), else: seek_file(position, state)
  end

  def handle_event(pad, event, ctx, state), do: super(pad, event, ctx, state)

  @impl true
  def handle_prepared_to_stopped(_ctx, %{fd: fd} = state) do
    with {:ok, state} <- maybe_merge_temporary(state),
         :ok <- mockable(CommonFile).close(fd) do
      {:ok, %{state | fd: nil}}
    else
      error -> Error.wrap_error(error, :close, state)
    end
  end

  defp seek_file(position, %{fd: fd} = state) do
    with {:ok, state} <- maybe_merge_temporary(state),
         {:ok, _position} <- mockable(CommonFile).seek(fd, position) do
      {:ok, state}
    else
      error -> Error.wrap_error(error, :seek_file, state)
    end
  end

  defp split_file(position, %{fd: fd} = state) do
    with {:ok, state} <- seek_file(position, state),
         {:ok, state} <- open_temporary(state),
         :ok <- mockable(CommonFile).split(fd, state.temp_fd) do
      {:ok, state}
    else
      error -> Error.wrap_error(error, :split_file, state)
    end
  end

  defp maybe_merge_temporary(%{temp_fd: nil} = state), do: {:ok, state}

  defp maybe_merge_temporary(%{fd: fd, temp_fd: temp_fd} = state) do
    with :ok <- mockable(CommonFile).copy(temp_fd, fd),
         {:ok, state} <- remove_temporary(state) do
      {:ok, state}
    else
      error -> Error.wrap_error(error, :merge_temporary, state)
    end
  end

  defp open_temporary(%{temp_fd: nil, temp_location: temp_location} = state) do
    case mockable(CommonFile).open(temp_location, [:read, :write]) do
      {:ok, temp_fd} -> {:ok, %{state | temp_fd: temp_fd}}
      error -> Error.wrap_error(error, :open_temporary, state)
    end
  end

  defp remove_temporary(%{temp_fd: temp_fd, temp_location: temp_location} = state) do
    with :ok <- mockable(CommonFile).close(temp_fd),
         :ok <- mockable(CommonFile).remove(temp_location) do
      {:ok, %{state | temp_fd: nil}}
    else
      error -> Error.wrap_error(error, :remove_temporary, state)
    end
  end
end
