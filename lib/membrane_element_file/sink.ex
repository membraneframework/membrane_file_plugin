defmodule Membrane.Element.File.Sink do
  use Membrane.Element.Base.Sink
  alias Membrane.Element.File.SinkOptions

  def_known_sink_pads %{
    :sink => {:always, :any}
  }


  # Private API

  @doc false
  def handle_init(%SinkOptions{location: location}) do
    {:ok, %{
      location: location,
      fd: nil
    }}
  end


  @doc false
  def handle_prepare(:stopped, %{location: location} = state) do
    case File.open(location, [:binary, :write]) do
      {:ok, fd} ->
        {:ok, %{state | fd: fd}}

      {:error, reason} ->
        {:error, {:open, reason}}
    end
  end


  @doc false
  def handle_stop(%{fd: fd} = state) do
    case File.close(fd) do
      :ok ->
        {:ok, %{state | fd: nil}}

      {:error, reason} ->
        {:error, {:close, reason}}
    end
  end


  @doc false
  def handle_buffer(:sink, _caps, data, %{fd: fd} = state) do
    case IO.binwrite(fd, data) do
      :ok ->
        {:ok, state}

      {:error, reason} ->
        {:error, {:write, reason}, state}
    end
  end
end
