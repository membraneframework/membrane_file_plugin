defmodule Membrane.Element.File.SinkOptions do
  defstruct location: nil

  @type t :: %Membrane.Element.File.SinkOptions{
    location: String.t
  }
end
