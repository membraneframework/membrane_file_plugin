defmodule Membrane.File.NewSeekEvent do
  @moduledoc """
  An event sent by the `Membrane.File.Source` with `seekable?: true` option,
  right after receiving `Membrane.File.SeekSourceEvent`.
  An element that steers the seekable file source with `Membrane.File.SeekSourceEvent`
  can assume that all the buffers received after receiving that event are
  the buffers ordered by that `Membrane.File.SeekSourceEvent`.
  """
  @derive Membrane.EventProtocol

  defstruct []
end
