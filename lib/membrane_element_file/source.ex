defmodule Membrane.Element.File.Source do
  use Membrane.Element.Base.Source
  alias Membrane.Element.File.SourceOptions
  alias Membrane.Buffer
  use Membrane.Helper


  def_known_source_pads %{
    :source => {:always, :pull, :any}
  }


  # Private API

  @doc false
  def handle_init(%SourceOptions{location: location, chunk_size: size}) do
    {:ok, %{
      location: location,
      chunk_size: size,
      file: nil,
    }}
  end


  @doc false
  def handle_prepare(:stopped, %{location: location} = state) do
    with {:ok, file} <- location |> File.open
    do {:ok, {[], %{state | file: file}}}
    else {:error, reason} -> {:error, {:open_file, reason}}
    end
  end

  @doc false
  def handle_demand1(:sink, _, %{file: file, chunk_size: size} = state) do
    with <<payload::binary>> <- file |> IO.binread(size)
    do {:ok, {[{:buffer, {:source, %Buffer{payload: payload}}}], state}}
    else
      :eof -> handle_stop state
      {:error, reason} -> {:error, {:read_file, reason}}
    end
  end

  @doc false
  def handle_stop(%{file: file} = state) do
    with :ok <- file ~> (Nil -> :ok; _ -> File.close file)
    do {:ok, state}
    else {:error, reason} -> {:error, {:close_file, reason}}
    end
  end

end
