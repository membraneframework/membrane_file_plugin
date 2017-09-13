defmodule Membrane.Element.File.Source.Options do
  defstruct \
    location: nil,
    chunk_size: 2048

  @type t :: %Membrane.Element.File.Source.Options{
    location: String.t,
    chunk_size: pos_integer,
  }
end
