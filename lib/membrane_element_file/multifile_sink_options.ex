defmodule Membrane.Element.File.Sink.Multi.Options do
  @type t :: %Membrane.Element.File.Sink.Multi.Options{
    naming_fun: (non_neg_integer -> String.t),
    split_event_type: atom,
  }

  defstruct \
    naming_fun: &__MODULE__.default_name/1,
    split_event_type: :split



  def default_name(i) do
    str_i = i
      |> Integer.to_string
      |> String.pad_leading(3, "0")
    "file#{str_i}"
  end
end
