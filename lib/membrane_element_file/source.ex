defmodule Membrane.Element.File.SourceOptions do
  defstruct location: nil

  @type t :: %Membrane.Element.File.SourceOptions{
    location: String.t
  }
end


defmodule Membrane.Element.File.Source do
  use Membrane.Element.Base.Source
  alias Membrane.Element.File.SourceOptions


  def handle_prepare(%SourceOptions{location: location}) do
    case File.open(location, [:binary, :read]) do
      {:ok, fd} ->
        {:ok, %{fd: fd}}

      {:error, reason} ->
        {:error, {:open, reason}}
    end
  end


  def handle_play(state) do
    # TODO
    {:ok, state}
  end
end
