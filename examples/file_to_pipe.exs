import Membrane.ChildrenSpec
import Membrane.Testing.Assertions
alias Membrane.Testing.Pipeline

LoggerBackends.add(LoggerBackends.Console)
LoggerBackends.configure(LoggerBackends.Console, device: :standard_error)

[input | _] = System.argv()

spec =
  child(%Membrane.File.Source{location: input})
  |> child(:sink, %Membrane.File.Sink{location: :stdout})

{:ok, _supervisor, pipeline} = Pipeline.start(spec: spec)

assert_end_of_stream(pipeline, :sink, :input)
Pipeline.terminate(pipeline)
