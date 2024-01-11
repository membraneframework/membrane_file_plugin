import Membrane.ChildrenSpec
import Membrane.Testing.Assertions
alias Membrane.Testing.Pipeline

LoggerBackends.add(LoggerBackends.Console)
LoggerBackends.configure(LoggerBackends.Console, device: :standard_error)

[output, chunk_size_str | _] = System.argv()
{chunk_size, ""} = Integer.parse(chunk_size_str)

spec =
  child(%Membrane.File.Source{location: :stdin, chunk_size: chunk_size})
  |> child(:sink, %Membrane.File.Sink{location: output})

{:ok, _supervisor, pipeline} = Pipeline.start(spec: spec)

assert_end_of_stream(pipeline, :sink, :input)
Pipeline.terminate(pipeline)
