defmodule Membrane.File.EndOfSeekEvent do
  @moduledoc """
  An event sent by the `Membrane.File.Source` with `seekable?: true` option,
  after it sent all the data requested by `Membrane.File.SeekSourceEvent` or
  whole file was read.
  """
  @derive Membrane.EventProtocol

  defstruct []
end
