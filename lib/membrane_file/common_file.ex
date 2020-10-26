defmodule Membrane.File.CommonFile do
  @moduledoc false

  def open(location \\ nil, mode, state) do
    location = location || state.location
    path = Path.expand(location)

    with {:ok, fd} <- File.open(path, [:binary, mode]) do
      {:ok, %{state | fd: fd}}
    else
      {:error, reason} -> {{:error, {:open, reason}}, state}
    end
  end

  def close(%{fd: fd} = state) do
    with :ok <- File.close(fd) do
      {:ok, %{state | fd: nil}}
    else
      {:error, reason} -> {{:error, {:close, reason}}, state}
    end
  end

  defdelegate binwrite(fd, data), to: IO

  defdelegate binread(fd, data), to: IO
end
