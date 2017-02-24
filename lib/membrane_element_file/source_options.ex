defmodule Membrane.Element.File.SourceOptions do
  defstruct location: nil

  @type t :: %Membrane.Element.File.SourceOptions{
    location: String.t
  }
end
