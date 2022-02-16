defmodule Membrane.File.CommonFile do
  @moduledoc false

  alias Membrane.{Buffer, Payload}
  alias Membrane.File.{Error, SeekEvent}

  @spec open(Path.t(), File.mode() | [File.mode() | :ram]) ::
          {:ok, File.io_device()} | Error.posix_error_t()
  def open(path, modes), do: File.open(path, [:binary | List.wrap(modes)])

  @spec write(File.io_device(), Buffer.t()) :: :ok | Error.posix_error_t()
  def write(fd, %Buffer{payload: payload}), do: IO.binwrite(fd, Payload.to_binary(payload))

  @spec seek(File.io_device(), SeekEvent.position_t()) ::
          {:ok, integer()} | Error.generic_error_t()
  def seek(fd, position), do: :file.position(fd, position)

  @spec copy(File.io_device(), File.io_device()) ::
          {:ok, non_neg_integer()} | Error.generic_error_t()
  def copy(source_fd, destination_fd) do
    with {:ok, src_position} <- :file.position(source_fd, :cur),
         {:ok, dst_position} <- :file.position(destination_fd, :cur),
         {:ok, bytes_copied} <- :file.copy(source_fd, destination_fd),
         {:ok, _src_position} <- :file.position(source_fd, src_position),
         {:ok, _dst_position} <- :file.position(destination_fd, dst_position) do
      {:ok, bytes_copied}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec split(File.io_device(), File.io_device()) :: :ok | Error.generic_error_t()
  def split(source_fd, destination_fd) do
    with {:ok, _bytes_copied} <- copy(source_fd, destination_fd),
         :ok <- truncate(source_fd) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec truncate(File.io_device()) :: :ok | Error.generic_error_t()
  defdelegate truncate(fd), to: :file

  @spec close(File.io_device()) :: :ok | Error.posix_error_t()
  defdelegate close(fd), to: File

  @spec rm(Path.t()) :: :ok | Error.posix_error_t()
  defdelegate rm(path), to: File

  @spec binread(File.io_device(), non_neg_integer()) :: iodata() | IO.nodata()
  defdelegate binread(fd, bytes_count), to: IO
end
