defmodule Membrane.Element.File.Source do
  use Membrane.Element.Base.Source
  alias Membrane.Element.File.SourceOptions
  alias Membrane.Buffer


  @read_chunk_size 2048

  def_known_source_pads %{
    :source => {:always, :any}
  }


  # Private API

  @doc false
  def handle_init(%SourceOptions{location: location}) do
    {:ok, %{
      location: location,
      stream: nil,
    }}
  end


  @doc false
  def handle_prepare(:stopped, %{location: location} = state) do
    stream = File.stream!(location, [], @read_chunk_size)
    {:ok, %{state | stream: stream}}
  end


  @doc false
  def handle_play(%{stream: stream} = state) do
    Task.async(fn ->
      stream
      |> Stream.map(fn(chunk) ->
        send(self(), {:membrane_element_file_source_chunk, chunk})
      end)
      |> Stream.run
    end)

    {:ok, state}
  end


  @doc false
  def handle_stop(state) do
    # TODO kill streaming task
    {:ok, state}
  end


  @doc false
  def handle_other({:membrane_element_file_source_chunk, chunk}, state) do
    {:ok, [
      {:send, {:source, %Buffer{payload: chunk}}}
    ], state}
  end
end
