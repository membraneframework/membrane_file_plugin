defmodule Membrane.Element.File.SplitEvent do
  @moduledoc """
  Default event that closes current and opens new file in
  `Membrane.Element.File.Sink.Multi`.
  """
  @derive Membrane.EventProtocol

  defstruct []
end
