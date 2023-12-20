import Membrane.ChildrenSpec
import Membrane.Testing.Assertions

alias Membrane.File.Source
alias Membrane.File.Sink
alias Membrane.Testing.Pipeline

[input | _] = System.argv()

spec = [
  child(%Membrane.File.Source{location: input})
  |> child(%Membrane.File.Sink{location: :stdout})
]

assert_start_of_stream(pipeline, :sink, :input)
assert_end_of_stream(pipeline, :sink, :input)
Pipeline.terminate(pipeline)
