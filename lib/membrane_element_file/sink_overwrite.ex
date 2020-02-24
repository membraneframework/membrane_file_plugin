defmodule Membrane.Element.File.Sink.Overwrite do
  use Membrane.Sink
  alias Membrane.Buffer

  def_options location: [type: :string, description: "Path to the file"]

  def_input_pad :input, demand_unit: :buffers, caps: :any

  # Private API

  @impl true
  def handle_init(%__MODULE__{location: location}) do
    {:ok, %{location: location}}
  end

  @impl true
  def handle_prepared_to_playing(_ctx, state) do
    {{:ok, demand: :input}, state}
  end

  @impl true
  def handle_write(:input, %Buffer{payload: payload}, _ctx, state) do
    bin_payload = Membrane.Payload.to_binary(payload)

    with :ok <- File.write(state.location, bin_payload, [:binary]) do
      {{:ok, demand: :input}, state}
    else
      {:error, reason} -> {{:error, {:write, reason}}, state}
    end
  end
end
