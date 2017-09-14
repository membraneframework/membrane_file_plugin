defmodule Membrane.Element.File.Sink.Multi do
  @moduledoc """
  """
  use Membrane.Element.Base.Sink
  alias Membrane.Element.File.Sink.Multi.Options
  alias Membrane.{Buffer, Event}


  def_known_sink_pads %{
    :sink => {:always, {:pull, demand_in: :buffers}, :any}
  }


  # Private API

  @doc false
  def handle_init(%Options{naming_fun: naming_fun, split_event_type: split_event_type}) do
    {:ok, %{
      naming_fun: naming_fun,
      split_on: split_event_type,
      fd: nil,
      index: 0,
    }}
  end


  @doc false
  def handle_prepare(:stopped, state) do
    state |> open_file
  end

  @doc false
  def handle_play(state) do
    {{:ok, demand: :sink}, state}
  end

  @doc false
  def handle_stop(state) do
    state |> close_file
  end

  @doc false
  def handle_event(:sink, %Event{type: received_event}, _params, %{split_on: expected_event} = state)
  when received_event == expected_event do
    with {:ok, closed_state} <- state |> close_file,
         updated_state       <- closed_state |> Map.update!(:index, &(&1 + 1)),
         {:ok, final_state}  <- updated_state |> open_file
    do
      {:ok, final_state}
    else
      error_ret -> error_ret
    end
  end

  @doc false
  def handle_write1(:sink, %Buffer{payload: payload}, _, %{fd: fd} = state) do
    with :ok <- IO.binwrite(fd, payload)
    do {{:ok, demand: :sink}, state}
    else {:error, reason} -> {{:error, {:write, reason}}, state}
    end
  end

  defp open_file(%{naming_fun: naming_fun, index: index} = state) do
    location = naming_fun.(index)
    with {:ok, fd} <- File.open(location, [:binary, :write])
    do {:ok, %{state | fd: fd}}
    else {:error, reason} -> {{:error, {:open, reason}}, state}
    end
  end

  defp close_file(%{fd: fd} = state) do
    with :ok <- File.close(fd)
    do {:ok, %{state | fd: nil}}
    else {:error, reason} -> {{:error, {:close, reason}}, state}
    end
  end
end
