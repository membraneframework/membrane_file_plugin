defmodule Membrane.File.Source do
  @moduledoc """
  Element that reads chunks of data from given file and sends them as buffers
  through the output pad.
  """

  use Membrane.Source
  alias Membrane.Buffer
  alias Membrane.File.{CommonFile, Error}

  import Mockery.Macro

  def_options location: [type: :string, description: "Path to the file"],
              chunk_size: [
                type: :integer,
                spec: pos_integer,
                default: 2048,
                description: "Size of chunks being read"
              ]

  def_output_pad :output, caps: :any

  # Private API

  @impl true
  def handle_init(%__MODULE__{location: location, chunk_size: size}) do
    {:ok,
     %{
       location: location,
       chunk_size: size,
       fd: nil
     }}
  end

  @impl true
  def handle_stopped_to_prepared(_ctx, %{location: location} = state) do
    case mockable(CommonFile).open(location, :read) do
      {:ok, fd} -> {:ok, %{state | fd: fd}}
      error -> Error.wrap_error(error, :open, state)
    end
  end

  @impl true
  def handle_demand(:output, _size, :buffers, _ctx, %{chunk_size: chunk_size} = state),
    do: supply_demand(chunk_size, [redemand: :output], state)

  def handle_demand(:output, size, :bytes, _ctx, state),
    do: supply_demand(size, [], state)

  def supply_demand(size, redemand, %{fd: fd} = state) do
    case mockable(CommonFile).binread(fd, size) do
      <<payload::binary>> ->
        {{:ok, [buffer: {:output, %Buffer{payload: payload}}] ++ redemand}, state}

      :eof ->
        {{:ok, end_of_stream: :output}, state}

      error ->
        Error.wrap_error(error, :read_file, state)
    end
  end

  @impl true
  def handle_prepared_to_stopped(_ctx, %{fd: fd} = state) do
    case mockable(CommonFile).close(fd) do
      :ok -> {:ok, %{state | fd: nil}}
      error -> Error.wrap_error(error, :close, state)
    end
  end
end
