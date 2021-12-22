defmodule Membrane.File.Sink.Multi do
  @moduledoc """
  Element that writes buffers to a set of files. File is switched on event.

  Files are named according to `naming_fun` passed in options.
  This function receives sequential number of file and should return string.
  It defaults to `path/to/file0.ext`, `path/to/file1.ext`, ...

  The event type, which starts writing to a next file is passed by `split_event` option.
  It defaults to `Membrane.File.SplitEvent`.
  """
  use Membrane.Sink
  import Mockery.Macro

  alias Membrane.File.{CommonFile, Error}

  def_options location: [
                spec: String.t(),
                description: "Base path to the file, will be passed to the naming function"
              ],
              extension: [
                spec: String.t(),
                default: "",
                description: """
                Extension of the file, should be preceeded with dot (.). It is
                passed to the naming function.
                """
              ],
              naming_fun: [
                spec: (String.t(), non_neg_integer, String.t() -> String.t()),
                default: &__MODULE__.default_naming_fun/3,
                description: """
                Function accepting base path, sequential number and file extension,
                and returning file path as a string. Default one generates
                path/to/file0.ext, path/to/file1.ext, ...
                """
              ],
              split_event: [
                spec: Membrane.Event.t(),
                default: Membrane.File.SplitEvent,
                description: "Event causing switching to a new file"
              ]

  @spec default_naming_fun(String.t(), non_neg_integer(), String.t()) :: String.t()
  def default_naming_fun(path, i, ext), do: "#{path}#{i}#{ext}"

  def_input_pad :input, demand_unit: :buffers, caps: :any

  @impl true
  def handle_init(%__MODULE__{} = options) do
    {:ok,
     %{
       naming_fun: &options.naming_fun.(options.location, &1, options.extension),
       split_on: options.split_event,
       fd: nil,
       index: 0
     }}
  end

  @impl true
  def handle_stopped_to_prepared(_ctx, state), do: open(state)

  @impl true
  def handle_prepared_to_playing(_ctx, state) do
    {{:ok, demand: :input}, state}
  end

  @impl true
  def handle_event(:input, %split_on{}, _ctx, %{split_on: split_on} = state) do
    with {:ok, state} <- close(state),
         {:ok, state} <- open(state) do
      {:ok, state}
    else
      error -> Error.wrap(error, :split, state)
    end
  end

  def handle_event(pad, event, ctx, state), do: super(pad, event, ctx, state)

  @impl true
  def handle_write(:input, buffer, _ctx, %{fd: fd} = state) do
    case mockable(CommonFile).write(fd, buffer) do
      :ok -> {{:ok, demand: :input}, state}
      error -> Error.wrap(error, :write, state)
    end
  end

  @impl true
  def handle_prepared_to_stopped(_ctx, state), do: close(state)

  defp open(%{naming_fun: naming_fun, index: index} = state) do
    case mockable(CommonFile).open(naming_fun.(index), :write) do
      {:ok, fd} -> {:ok, %{state | fd: fd}}
      error -> Error.wrap(error, :open, state)
    end
  end

  defp close(%{fd: fd, index: index} = state) do
    case mockable(CommonFile).close(fd) do
      :ok -> {:ok, %{state | fd: nil, index: index + 1}}
      error -> Error.wrap(error, :close, state)
    end
  end
end
