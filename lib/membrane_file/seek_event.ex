defmodule Membrane.File.SeekEvent do
  @moduledoc """
  Event that triggers seeking or insertion to a file in `Membrane.File.Sink`.
  """
  @derive Membrane.EventProtocol

  @type t :: %__MODULE__{
          position: Membrane.File.CommonFile.position_t(),
          insert?: boolean()
        }

  defstruct [:position, insert?: false]
end
