defmodule Membrane.Element.File.Source do
  use Membrane.Element.Base.Source
  alias Membrane.Element.File.Source.Options
  alias Membrane.{Buffer, Event}
  use Membrane.Helper


  def_known_source_pads %{
    :source => {:always, :pull, :any}
  }


  # Private API

  @doc false
  def handle_init(%Options{location: location, chunk_size: size}) do
    {:ok, %{
      location: location,
      chunk_size: size,
      file: nil,
    }}
  end


  @doc false
  def handle_prepare(:stopped, %{location: location} = state) do
    with {:ok, file} <- location |> File.open
    do {:ok, %{state | file: file}}
    else {:error, reason} -> {{:error, {:open_file, reason}}, state}
    end
  end
  def handle_prepare(_, state), do: {:ok, state}

  @doc false
  def handle_demand1(:source, _, %{chunk_size: chunk_size} = state), do:
    read_send(chunk_size, state)

  def handle_demand(:source, size, :bytes, _, state), do:
    read_send(size, state)

  def handle_demand(:source, size, :buffers, params, state), do:
    super(:source, size, :buffers, params, state)

  defp read_send(size, %{file: file} = state) do
    with <<payload::binary>> <- file |> IO.binread(size)
    do {{:ok, buffer: {:source, %Buffer{payload: payload}}}, state}
    else
      :eof -> {{:ok, event: {:source, Event.eos}}, state}
      {:error, reason} -> {{:error, {:read_file, reason}}, state}
    end
  end

  @doc false
  def handle_stop(%{file: file} = state) do
    with :ok <- file ~> (Nil -> :ok; _ -> File.close file)
    do {:ok, state}
    else {:error, reason} -> {{:error, {:close_file, reason}}, state}
    end
  end

  def handle_shutdown(%{file: file}) do
    if file != nil, do: File.close file
    :ok
  end

end
