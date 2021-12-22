defmodule Membrane.File.Error do
  @moduledoc false

  @type posix_error_t() :: {:error, File.posix()}
  @type generic_error_t() :: {:error, File.posix() | :badarg | :terminated}

  @spec wrap_error({:error, any()} | {{:error, any()}, any()}, atom(), any()) ::
          {{:error, {atom(), any()}}, any()}
  def wrap_error({:error, reason}, wrap_reason, state),
    do: {{:error, {wrap_reason, reason}}, state}

  def wrap_error({{:error, reason}, state}, wrap_reason, state),
    do: {{:error, {wrap_reason, reason}}, state}
end
