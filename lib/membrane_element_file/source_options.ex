defmodule Membrane.Element.File.SourceOptions do
  defstruct \
    location: nil,
    chunk_size: 2048

  @type t :: %Membrane.Element.File.SourceOptions{
    location: String.t,
    chunk_size: pos_integer,
  }
end
