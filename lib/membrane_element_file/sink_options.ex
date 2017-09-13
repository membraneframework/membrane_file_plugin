defmodule Membrane.Element.File.Sink.Options do
  defstruct location: nil

  @type t :: %Membrane.Element.File.Sink.Options{
    location: String.t
  }
end
