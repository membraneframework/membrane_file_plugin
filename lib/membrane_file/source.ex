defmodule Membrane.File.Source do
  @moduledoc """
  Element that reads chunks of data from given file and sends them as buffers
  through the output pad.
  """
  use Membrane.Source
  import Mockery.Macro

  alias Membrane.{Buffer, RemoteStream}
  alias Membrane.File.{CommonFile, Error}

  def_options location: [
                spec: Path.t(),
                description: "Path to the file"
              ],
              chunk_size: [
                spec: pos_integer(),
                default: 2048,
                description: "Size of chunks being read"
              ]

  def_output_pad :output, caps: {RemoteStream, type: :packetized}

  @impl true
  def handle_init(%__MODULE__{location: location, chunk_size: size}) do
    {:ok,
     %{
       location: Path.expand(location),
       chunk_size: size,
       fd: nil
     }}
  end

  @impl true
  def handle_stopped_to_prepared(_ctx, %{location: location} = state) do
    case mockable(CommonFile).open(location, :read) do
      {:ok, fd} -> {:ok, %{state | fd: fd}}
      error -> Error.wrap(error, :open, state)
    end
  end

  @impl true
  def handle_prepared_to_playing(_ctx, state) do
    {{:ok, caps: {:output, %RemoteStream{type: :packetized}}}, state}
  end

  @impl true
  def handle_demand(:output, _size, :buffers, _ctx, %{chunk_size: chunk_size} = state),
    do: supply_demand(chunk_size, [redemand: :output], state)

  def handle_demand(:output, size, :bytes, _ctx, state),
    do: supply_demand(size, [], state)

  defp supply_demand(size, redemand, %{fd: fd} = state) do
    case mockable(CommonFile).binread(fd, size) do
      <<payload::binary>> ->
        {{:ok, [buffer: {:output, %Buffer{payload: payload}}] ++ redemand}, state}

      :eof ->
        {{:ok, end_of_stream: :output}, state}

      error ->
        Error.wrap(error, :read_file, state)
    end
  end

  @impl true
  def handle_prepared_to_stopped(_ctx, %{fd: fd} = state) do
    case mockable(CommonFile).close(fd) do
      :ok -> {:ok, %{state | fd: nil}}
      error -> Error.wrap(error, :close, state)
    end
  end
end
