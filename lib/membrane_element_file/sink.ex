defmodule Membrane.Element.File.Sink do
  use Membrane.Element.Base.Sink
  alias Membrane.Buffer

  @f Mockery.of(Membrane.Element.File.CommonFile)

  @type t :: %__MODULE__{
          location: String.t()
        }

  def_options location: [type: :string, description: "Path to the file"]

  def_known_sink_pads sink: {:always, {:pull, demand_in: :buffers}, :any}

  # Private API

  @impl true
  def handle_init(%__MODULE__{location: location}) do
    {:ok,
     %{
       location: location,
       fd: nil
     }}
  end

  @impl true
  def handle_prepare(:stopped, state), do: @f.open(:write, state)
  def handle_prepare(_, state), do: {:ok, state}

  @impl true
  def handle_play(state) do
    {{:ok, demand: :sink}, state}
  end

  @impl true
  def handle_write1(:sink, %Buffer{payload: payload}, _, %{fd: fd} = state) do
    with :ok <- @f.binwrite(fd, payload) do
      {{:ok, demand: :sink}, state}
    else
      {:error, reason} -> {{:error, {:write, reason}}, state}
    end
  end

  @impl true
  def handle_stop(state), do: @f.close(state)
end
