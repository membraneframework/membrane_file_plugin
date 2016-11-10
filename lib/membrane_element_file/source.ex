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


  def handle_prepare(%SourceOptions{location: location}) do
    stream = File.stream!(location, [], @read_chunk_size)
    {:ok, %{stream: stream}}
  end


  def handle_play(%{stream: stream} = state) do
    # TODO kill that task when we call stop()
    me = self

    Task.async(fn ->
      stream
      |> Stream.map(fn(chunk) ->
        Membrane.Element.send_buffer(me, %Membrane.Caps{content: "application/octet-stream"}, chunk) 
      end)
      |> Stream.run
    end)

    {:ok, state}
  end
end
