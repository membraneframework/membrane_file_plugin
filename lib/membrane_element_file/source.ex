defmodule Membrane.Element.File.SourceOptions do
  defstruct location: nil

  @type t :: %Membrane.Element.File.SourceOptions{
    location: String.t
  }
end


defmodule Membrane.Element.File.Source do
  use Membrane.Element.Base.Source
  alias Membrane.Element.File.SourceOptions


  @read_chunk_size 2048


  # Private API

  @doc false
  def handle_init(%SourceOptions{location: location}) do
    {:ok, %{
      location: location,
      stream: nil,
    }}
  end


  @doc false
  def handle_prepare(%{location: location} = state) do
    stream = File.stream!(location, [], @read_chunk_size)
    {:ok, %{state | stream: stream}}
  end


  @doc false
  def handle_play(%{stream: stream} = state) do
    me = self

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
    {:send, [%Membrane.Buffer{payload: chunk}], state}
  end
end
