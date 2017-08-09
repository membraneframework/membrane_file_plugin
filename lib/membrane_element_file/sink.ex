defmodule Membrane.Element.File.Sink do
  use Membrane.Element.Base.Sink
  alias Membrane.Element.File.SinkOptions
  alias Membrane.Buffer


  def_known_sink_pads %{
    :sink => {:always, :pull, :any}
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
    with {:ok, fd} <- File.open(location, [:binary, :write])
    do {:ok, {[], %{state | fd: fd}}}
    else {:error, reason} -> {:error, {:open, reason}}
    end
  end


  @doc false
  def handle_stop(%{fd: fd} = state) do
    with :ok <- File.close(fd)
    do {:ok, {[], %{state | fd: nil}}}
    else {:error, reason} -> {:error, {:close, reason}}
    end
  end


  @doc false
  def handle_write1(:sink, %Buffer{payload: payload}, _, %{fd: fd} = state) do
    with :ok <- IO.binwrite(fd, payload)
    do {:ok, {[demand: :sink], state}}
    else {:error, reason} -> {:error, {:write, reason}}
    end
  end
end
