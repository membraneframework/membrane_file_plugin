defmodule Membrane.File.SeekSourceEvent do
  @moduledoc """
  An event that triggers seeking in `Membrane.File.Source`.
  """
  @derive Membrane.EventProtocol

  @type offset_t :: integer()
  @type position_t :: offset_t() | {:bof | :cur | :eof, offset_t()} | :bof | :cur | :eof

  @type t :: %__MODULE__{
          start: position_t(),
          size_to_read: non_neg_integer(),
          last?: boolean()
        }

  defstruct [:start, :size_to_read, last?: false]
end
