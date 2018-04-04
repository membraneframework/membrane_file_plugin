defmodule Membrane.Element.File.Sink.Multi do
  @moduledoc """
  Writes bufffers to a set of files. File is switched on event.

  Files are named according to naming_fun passed in options.
  This function receives sequential number of file and should return string.
  It defaults to file000, file001, ...

  The event type, which starts writing to a next file,
  is passed as atom in `split_on` option.
  It defaults to `:split`.
  """
  use Membrane.Element.Base.Sink
  alias Membrane.{Buffer, Event}

  @f Mockery.of(Membrane.Element.File.CommonFile)

  @type t :: %__MODULE__{
          location: String.t(),
          extension: String.t(),
          naming_fun: (String.t(), non_neg_integer, String.t() -> String.t()),
          split_event_type: atom
        }

  def_options location: [
                type: :string,
                description: "Base path to the file, will be passed to the naming function"
              ],
              extension: [
                type: :string,
                default: "",
                description: "Extension of the file, should be preceeded with dot (.)"
              ],
              naming_fun: [
                type: :function,
                default: &__MODULE__.default_naming_fun/3,
                description: "Function accepting base path, sequential number and file extension,
        and returning file path as a string. Default one generates
        path/to/file0.ext, path/to/file1.ext, ..."
              ],
              split_event_type: [
                type: :atom,
                default: :split,
                description: "Type of event causing switching to a new file"
              ]

  def default_naming_fun(path, i, ext), do: "#{path}#{i}#{ext}"

  def_known_sink_pads sink: {:always, {:pull, demand_in: :buffers}, :any}

  # Private API

  @impl true
  def handle_init(%__MODULE__{} = options) do
    {:ok,
     %{
       naming_fun: &options.naming_fun.(options.location, &1, options.extension),
       split_on: options.split_event_type,
       fd: nil,
       index: 0
     }}
  end

  @impl true
  def handle_prepare(:stopped, state) do
    @f.open(state.naming_fun.(state.index), :write, state)
  end

  @impl true
  def handle_play(state) do
    {{:ok, demand: :sink}, state}
  end

  @impl true
  def handle_event(:sink, %Event{type: split_on}, _ctx, %{split_on: split_on} = state) do
    with {:ok, state} <- state |> @f.close do
      state = state |> Map.update!(:index, &(&1 + 1))
      @f.open(state.naming_fun.(state.index), :write, state)
    end
  end

  def handle_event(pad, event, ctx, state), do: super(pad, event, ctx, state)

  @impl true
  def handle_write1(:sink, %Buffer{payload: payload}, _, %{fd: fd} = state) do
    with :ok <- @f.binwrite(fd, payload) do
      {{:ok, demand: :sink}, state}
    else
      {:error, reason} -> {{:error, {:write, reason}}, state}
    end
  end

  @impl true
  def handle_stop(state) do
    state = state |> Map.update!(:index, &(&1 + 1))
    state |> @f.close
  end
end
