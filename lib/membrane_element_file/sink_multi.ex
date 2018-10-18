defmodule Membrane.Element.File.Sink.Multi do
  @moduledoc """
  Element that writes buffers to a set of files. File is switched on event.

  Files are named according to naming_fun passed in options.
  This function receives sequential number of file and should return string.
  It defaults to file000, file001, ...

  The event type, which starts writing to a next file,
  is passed as atom in `split_on` option.
  It defaults to `:split`.
  """
  use Membrane.Element.Base.Sink
  alias Membrane.Buffer
  alias Membrane.Element.File.CommonFile

  import Mockery.Macro

  def_options location: [
                type: :string,
                description: "Base path to the file, will be passed to the naming function"
              ],
              extension: [
                type: :string,
                default: "",
                description: """
                Extension of the file, should be preceeded with dot (.). It is
                passed to the naming function.
                """
              ],
              naming_fun: [
                type: :function,
                spec: (String.t(), non_neg_integer, String.t() -> String.t()),
                default: &__MODULE__.default_naming_fun/3,
                description: """
                Function accepting base path, sequential number and file extension,
                and returning file path as a string. Default one generates
                path/to/file0.ext, path/to/file1.ext, ...
                """
              ],
              split_event: [
                type: :struct,
                default: %__MODULE__.Split{},
                description: "Event causing switching to a new file"
              ]

  def default_naming_fun(path, i, ext), do: "#{path}#{i}#{ext}"

  def_input_pads input: [demand_unit: :buffers, caps: :any]

  # Private API

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
  def handle_stopped_to_prepared(_ctx, state) do
    mockable(CommonFile).open(state.naming_fun.(state.index), :write, state)
  end

  @impl true
  def handle_prepared_to_playing(_ctx, state) do
    {{:ok, demand: :input}, state}
  end

  @impl true
  def handle_event(:input, split_on, _ctx, %{split_on: split_on} = state) do
    with {:ok, state} <- state |> mockable(CommonFile).close do
      state = state |> Map.update!(:index, &(&1 + 1))
      mockable(CommonFile).open(state.naming_fun.(state.index), :write, state)
    end
  end

  def handle_event(pad, event, ctx, state), do: super(pad, event, ctx, state)

  @impl true
  def handle_write(:input, %Buffer{payload: payload}, _ctx, %{fd: fd} = state) do
    with :ok <- mockable(CommonFile).binwrite(fd, payload) do
      {{:ok, demand: :input}, state}
    else
      {:error, reason} -> {{:error, {:write, reason}}, state}
    end
  end

  @impl true
  def handle_prepared_to_stopped(_ctx, state) do
    state = state |> Map.update!(:index, &(&1 + 1))
    state |> mockable(CommonFile).close
  end
end
