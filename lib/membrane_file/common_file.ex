defmodule Membrane.File.CommonFile do
  @moduledoc false

  alias Membrane.{Buffer, Payload}
  alias Membrane.File.SeekEvent

  @type posix_error_t :: {:error, File.posix()}
  @type generic_error_t :: {:error, File.posix() | :badarg | :terminated}

  @spec open(Path.t(), File.mode() | [File.mode() | :ram]) ::
          {:ok, File.io_device()} | posix_error_t()
  def open(path, modes), do: File.open(path, [:binary | List.wrap(modes)])

  @spec open!(Path.t(), File.mode() | [File.mode() | :ram]) :: File.io_device()
  def open!(path, modes) do
    case open(path, modes) do
      {:ok, io_device} -> io_device
      {:error, posix_error} -> raise "Failed to open file '#{path}': #{inspect(posix_error)}"
    end
  end

  @spec write(File.io_device(), Buffer.t()) :: :ok | posix_error_t()
  def write(fd, %Buffer{payload: payload}), do: IO.binwrite(fd, Payload.to_binary(payload))

  @spec write!(File.io_device(), Buffer.t()) :: :ok
  def write!(fd, buffer) do
    case write(fd, buffer) do
      :ok -> :ok
      {:error, error} -> raise "Failed to write to a file #{inspect(fd)}: #{inspect(error)}"
    end
  end

  @spec seek(File.io_device(), SeekEvent.position_t()) ::
          {:ok, integer()} | generic_error_t()
  def seek(fd, position), do: :file.position(fd, position)

  @spec seek!(File.io_device(), SeekEvent.position_t()) :: integer()
  def seek!(fd, position) do
    case seek(fd, position) do
      {:ok, new_position} ->
        new_position

      {:error, error} ->
        raise "Failed to seek #{inspect(fd)} to position #{position}: #{inspect(error)}"
    end
  end

  @spec copy(File.io_device(), File.io_device()) ::
          {:ok, non_neg_integer()} | generic_error_t()
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

  @spec copy!(File.io_device(), File.io_device()) :: non_neg_integer()
  def copy!(src_fd, dest_fd) do
    case copy(src_fd, dest_fd) do
      {:ok, bytes_copied} ->
        bytes_copied

      {:error, reason} ->
        raise "Failed to copy #{inspect(src_fd)} to #{inspect(dest_fd)}: #{inspect(reason)}"
    end
  end

  @spec split(File.io_device(), File.io_device()) :: :ok | generic_error_t()
  def split(source_fd, destination_fd) do
    with {:ok, _bytes_copied} <- copy(source_fd, destination_fd),
         :ok <- truncate(source_fd) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec split!(File.io_device(), File.io_device()) :: :ok
  def split!(src_fd, dest_fd) do
    case split(src_fd, dest_fd) do
      :ok ->
        :ok

      {:error, reason} ->
        raise "Failed to split #{inspect(src_fd)} into #{inspect(dest_fd)}: #{inspect(reason)}"
    end
  end

  @spec truncate(File.io_device()) :: :ok | generic_error_t()
  defdelegate truncate(fd), to: :file

  @spec truncate!(File.io_device()) :: :ok
  def truncate!(fd) do
    case truncate(fd) do
      :ok -> :ok
      {:error, reason} -> raise "Failed to truncate file #{inspect(fd)}: #{inspect(reason)}"
    end
  end

  @spec close(File.io_device()) :: :ok | posix_error_t()
  defdelegate close(fd), to: File

  @spec close!(File.io_device()) :: :ok
  def close!(fd) do
    case close(fd) do
      :ok ->
        :ok

      {:error, reason} ->
        raise "Failed to close file #{inspect(fd)}: #{inspect(reason)}"
    end
  end

  @spec rm(Path.t()) :: :ok | posix_error_t()
  defdelegate rm(path), to: File

  @spec rm!(Path.t()) :: :ok
  defdelegate rm!(path), to: File

  @spec binread(File.io_device(), non_neg_integer()) :: iodata() | IO.nodata()
  defdelegate binread(fd, bytes_count), to: IO

  @spec binread!(File.io_device(), non_neg_integer()) :: iodata() | :eof
  def binread!(fd, bytes_count) do
    case binread(fd, bytes_count) do
      {:error, reason} -> raise "Failed to read from #{inspect(fd)}: #{inspect(reason)}"
      result -> result
    end
  end
end
