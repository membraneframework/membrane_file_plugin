defmodule Membrane.File.SeekSourceEvent do
  @moduledoc """
  Event that triggers seeking and reading in `Membrane.File.Source` working in
  `seekable?: true` mode.

  When `inspect(__MODULE__)` is received by the source, the source starts reading
  data from the given position in file, specified by the `:start` field of the event's
  struct. The source reads up to `size_to_read` bytes of the data from file (it can
  read less if the file ends).
  If the event is set with `last?: true`, once `size_to_read` bytes are read or the
  file ends, the source will return `end_of_stream` action on the `:output` pad.
  """
  @derive Membrane.EventProtocol

  @type offset_t :: integer()

  @typedoc """
  Specifies the position to which the seek is performed.

  The meaning is the same as for the `Location` argument in https://www.erlang.org/doc/man/file.html#position-2.
  """
  @type position_t :: offset_t() | {:bof | :cur | :eof, offset_t()} | :bof | :cur | :eof

  @type t :: %__MODULE__{
          start: position_t(),
          size_to_read: non_neg_integer() | :infinity,
          last?: boolean()
        }
  @enforce_keys [:start, :size_to_read]
  defstruct @enforce_keys ++ [last?: false]
end
