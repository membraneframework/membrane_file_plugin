defmodule Membrane.File.Source do
  @moduledoc """
  Element that reads chunks of data from given file and sends them as buffers
  through the output pad.

  Can work in two modes, determined by the `seekable?` option.
  With `seekable?: false`, the source will start reading data from the file exactly the moment it starts
  playing and will read it till the end of file, setting the `end_of_stream` action on the `:output` pad
  when the reading is done.
  With `seekable?: true`, the process of reading is driven by receiving `Membrane.File.SeekSourceEvent` events.
  The source working in `seekable?: true` mode won't send any data before that event is received.
  For more information about how to steer reading in `seekable?: true` mode, see: `Membrane.File.SeekSourceEvent`.
  """
  use Membrane.Source

  alias Membrane.{Buffer, RemoteStream}
  alias Membrane.File.SeekSourceEvent

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
              seekable?: [
                spec: boolean(),
                default: false,
                description: """
                If true, the source will be steered by the `Membrane.File.SeekSourceEvent`
                events. Defaults to false.
                """
              ]

  def_output_pad :output, accepted_format: %RemoteStream{type: :bytestream}

  @impl true
  def handle_init(_ctx, %__MODULE__{location: location, chunk_size: size, seekable?: seekable?}) do
    size_to_read = if seekable?, do: 0, else: :infinity

    {[],
     %{
       location: Path.expand(location),
       chunk_size: size,
       fd: nil,
       should_send_eos?: not seekable?,
       size_to_read: size_to_read,
       seekable?: seekable?
     }}
  end

  @impl true
  def handle_setup(_ctx, %{location: location} = state) do
    fd = @common_file.open!(location, :read)

    {[], %{state | fd: fd}}
  end

  @impl true
  def handle_playing(_ctx, state) do
    {[stream_format: {:output, %RemoteStream{type: :bytestream}}], state}
  end

  @impl true
  def handle_event(
        :output,
        %SeekSourceEvent{start: seek_start, size_to_read: size_to_read, last?: last?},
        _ctx,
        %{seekable?: true} = state
      ) do
    @common_file.seek!(state.fd, seek_start)
    {[redemand: :output], %{state | should_send_eos?: last?, size_to_read: size_to_read}}
  end

  @impl true
  def handle_event(
        :output,
        %SeekSourceEvent{},
        _ctx,
        %{seekable?: false}
      ) do
    raise "Cannot handle `Membrane.File.SeekSourceEvent` in a `#{__MODULE__}` with `seekable?: false` option."
  end

  @impl true
  def handle_demand(:output, _size, :buffers, _ctx, %{chunk_size: chunk_size} = state),
    do: supply_demand(chunk_size, [redemand: :output], state)

  def handle_demand(:output, size, :bytes, _ctx, state),
    do: supply_demand(size, [], state)

  @impl true
  def handle_terminate_request(_ctx, state) do
    @common_file.close!(state.fd)

    {[terminate: :normal], %{state | fd: nil}}
  end

  defp supply_demand(demand_size, redemand, %{size_to_read: :infinity} = state) do
    do_supply_demand(demand_size, redemand, state)
  end

  defp supply_demand(_demand_size, _redemand, %{size_to_read: 0} = state) do
    {[], state}
  end

  defp supply_demand(demand_size, redemand, %{size_to_read: size_to_read} = state) do
    do_supply_demand(min(demand_size, size_to_read), redemand, state)
  end

  defp do_supply_demand(to_supply_size, redemand, state) do
    {buffer_actions, supplied_size} =
      case @common_file.binread!(state.fd, to_supply_size) do
        <<payload::binary>> ->
          {[buffer: {:output, %Buffer{payload: payload}}], byte_size(payload)}

        :eof ->
          {[], 0}
      end

    new_size_to_read =
      if state.size_to_read == :infinity, do: :infinity, else: state.size_to_read - supplied_size

    state = %{state | size_to_read: new_size_to_read}

    actions =
      buffer_actions ++
        if state.should_send_eos? and (state.size_to_read == 0 or supplied_size < to_supply_size) do
          [end_of_stream: :output]
        else
          if to_supply_size == supplied_size do
            redemand
          else
            []
          end
        end

    {actions, state}
  end
end
