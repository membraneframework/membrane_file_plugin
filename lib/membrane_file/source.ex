defmodule Membrane.File.Source do
  @moduledoc """
  Element that reads chunks of data from given file and sends them as buffers
  through the output pad.
  """
  use Membrane.Source

  alias Membrane.{Buffer, RemoteStream}

  @common_file Membrane.File.CommonFileBehaviour.get_impl()

  def_options location: [
                spec: Path.t(),
                description: "Path to the file"
              ],
              chunk_size: [
                spec: pos_integer(),
                default: 2048,
                description: "Size of chunks being read"
              ],
              content_format: [
                spec: module() | nil,
                default: nil,
                description: "Module for `RemoteStream.t()` caps sent by output pad"
              ]

  def_output_pad :output, caps: {RemoteStream, type: :bytestream}

  @impl true
  def handle_init(options) do
    state =
      options
      |> Map.from_struct()
      |> Map.update!(:location, &Path.expand/1)
      |> Map.put(:fd, nil)

    {:ok, state}
  end

  @impl true
  def handle_stopped_to_prepared(_ctx, %{location: location} = state) do
    fd = @common_file.open!(location, :read)
    {:ok, %{state | fd: fd}}
  end

  @impl true
  def handle_prepared_to_playing(_ctx, state) do
    output_format = %RemoteStream{type: :bytestream, content_format: state.content_format}

    {{:ok, caps: {:output, output_format}}, state}
  end

  @impl true
  def handle_demand(:output, _size, :buffers, _ctx, %{chunk_size: chunk_size} = state),
    do: supply_demand(chunk_size, [redemand: :output], state)

  def handle_demand(:output, size, :bytes, _ctx, state),
    do: supply_demand(size, [], state)

  defp supply_demand(size, redemand, %{fd: fd} = state) do
    actions =
      case @common_file.binread!(fd, size) do
        <<payload::binary>> when byte_size(payload) == size ->
          [buffer: {:output, %Buffer{payload: payload}}] ++ redemand

        <<payload::binary>> when byte_size(payload) < size ->
          [buffer: {:output, %Buffer{payload: payload}}, end_of_stream: :output]

        :eof ->
          [end_of_stream: :output]
      end

    {{:ok, actions}, state}
  end

  @impl true
  def handle_prepared_to_stopped(_ctx, %{fd: fd} = state) do
    :ok = @common_file.close!(fd)
    {:ok, %{state | fd: nil}}
  end
end
