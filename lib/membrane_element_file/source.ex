defmodule Membrane.Element.File.Source do
  @moduledoc """
  Element that reads chunks of data from given file and sends them as buffers
  through the source pad.
  """

  use Membrane.Element.Base.Source
  alias Membrane.{Buffer, Event}
  use Membrane.Helper

  @f Mockery.of(Membrane.Element.File.CommonFile)

  @type t :: %__MODULE__{
          location: String.t(),
          chunk_size: pos_integer
        }

  def_options location: [type: :string, description: "Path to the file"],
              chunk_size: [
                type: :integer,
                default: 2048,
                description: "Size of chunks being read"
              ]

  def_known_source_pads source: {:always, :pull, :any}

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
  def handle_prepare(:stopped, state), do: @f.open(:read, state)
  def handle_prepare(_, state), do: {:ok, state}

  @impl true
  def handle_demand1(:source, _, %{chunk_size: chunk_size} = state),
    do: read_send(chunk_size, state)

  @impl true
  def handle_demand(:source, size, :bytes, _, state), do: read_send(size, state)

  def handle_demand(:source, size, :buffers, params, state),
    do: super(:source, size, :buffers, params, state)

  defp read_send(size, %{fd: fd} = state) do
    with <<payload::binary>> <- fd |> @f.binread(size) do
      {{:ok, buffer: {:source, %Buffer{payload: payload}}}, state}
    else
      :eof -> {{:ok, event: {:source, Event.eos()}}, state}
      {:error, reason} -> {{:error, {:read_file, reason}}, state}
    end
  end

  @impl true
  def handle_stop(state), do: @f.close(state)
end
