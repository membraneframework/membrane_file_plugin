defmodule Membrane.Element.File.SinkOptions do
  defstruct location: nil

  @type t :: %Membrane.Element.File.SinkOptions{
    location: String.t
  }
end


defmodule Membrane.Element.File.Sink do
  use Membrane.Element.Base.Sink
  alias Membrane.Element.File.SinkOptions


  def handle_prepare(%SinkOptions{location: location}) do
    case File.open(location, [:binary, :write]) do
      {:ok, fd} ->
        {:ok, %{fd: fd}}

      {:error, reason} ->
        {:error, {:open, reason}}
    end
  end


  def handle_buffer(_caps, data, %{fd: fd} = state) do
    case IO.binwrite(fd, data) do
      :ok ->
        {:ok, state}

      {:error, reason} ->
        {:error, {:write, reason}, state}
    end
  end
end
