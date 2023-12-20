import Membrane.ChildrenSpec
import Membrane.Testing.Assertions

alias Membrane.File.Source
alias Membrane.File.Sink
alias Membrane.Testing.Pipeline

[output | _] = System.argv()

spec = [
  child(%Membrane.File.Source{location: :stdin})
  |> child(:sink, %Membrane.File.Sink{location: output})
]

{:ok, _supervisor, pipeline} = Pipeline.start(spec: spec)

assert_start_of_stream(pipeline, :sink, :input)
assert_end_of_stream(pipeline, :sink, :input)
Pipeline.terminate(pipeline)
