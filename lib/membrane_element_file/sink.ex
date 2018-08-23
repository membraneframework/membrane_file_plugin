defmodule Membrane.Element.File.Sink do
  @moduledoc """
  Element that creates a file and stores incoming buffers there (in binary format).
  """

  use Membrane.Element.Base.Sink
  alias Membrane.Buffer
  alias Membrane.Element.File.CommonFile

  import Mockery.Macro

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
  def handle_prepare(:stopped, _, state), do: mockable(CommonFile).open(:write, state)
  def handle_prepare(_, _, state), do: {:ok, state}

  @impl true
  def handle_play(_, state) do
    {{:ok, demand: :sink}, state}
  end

  @impl true
  def handle_write1(:sink, %Buffer{payload: payload}, _, %{fd: fd} = state) do
    with :ok <- mockable(CommonFile).binwrite(fd, payload) do
      {{:ok, demand: :sink}, state}
    else
      {:error, reason} -> {{:error, {:write, reason}}, state}
    end
  end

  @impl true
  def handle_stop(_, state), do: mockable(CommonFile).close(state)
end
