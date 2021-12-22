defmodule Membrane.File.SeekEvent do
  @moduledoc """
  Event that triggers seeking or insertion to a file in `Membrane.File.Sink`.
  """
  @derive Membrane.EventProtocol

  @type offset_t :: integer()
  @type position_t :: offset_t() | {:bof | :cur | :eof, offset_t()} | :bof | :cur | :eof

  @type t :: %__MODULE__{
          position: position_t(),
          insert?: boolean()
        }

  defstruct [:position, insert?: false]
end
