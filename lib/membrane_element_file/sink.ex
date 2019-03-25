defmodule Membrane.Element.File.Sink do
  @moduledoc """
  Element that creates a file and stores incoming buffers there (in binary format).
  """

  use Membrane.Element.Base.Sink
  alias Membrane.Buffer
  alias Membrane.Element.File.CommonFile

  import Mockery.Macro

  def_options location: [type: :string, description: "Path to the file"]

  def_input_pad :input, demand_unit: :buffers, caps: :any

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
  def handle_stopped_to_prepared(_ctx, state), do: mockable(CommonFile).open(:write, state)

  @impl true
  def handle_prepared_to_playing(_ctx, state) do
    {{:ok, demand: :input}, state}
  end

  @impl true
  def handle_write(:input, %Buffer{payload: payload}, _ctx, %{fd: fd} = state) do
    bin_payload = Membrane.Payload.to_binary(payload)

    with :ok <- mockable(CommonFile).binwrite(fd, bin_payload) do
      {{:ok, demand: :input}, state}
    else
      {:error, reason} -> {{:error, {:write, reason}}, state}
    end
  end

  @impl true
  def handle_prepared_to_stopped(_ctx, state), do: mockable(CommonFile).close(state)
end
