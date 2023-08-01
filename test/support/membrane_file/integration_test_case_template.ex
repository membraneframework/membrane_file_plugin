defmodule Membrane.File.IntegrationTestCaseTemplate do
  @moduledoc false
  use ExUnit.CaseTemplate, async: false

  import Mox

  setup :set_mox_global

  setup _ do
    Mox.stub_with(Membrane.File.CommonMock, Membrane.File.CommonFile)
    :ok
  end
end
