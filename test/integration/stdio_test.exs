defmodule Membrane.File.Integration.StdioTest do
  use ExUnit.Case, async: false
  @moduletag timeout: 360_000

  require Logger

  @input_text_file "test/fixtures/input.txt"
  @cmd_out_prefix "/tmp/membrane_file_test_out"
  @cmd_err_prefix "/tmp/membrane_file_test_err"

  setup_all(_context) do
    assert Mix.Task.run("compile", ["test/fixtures/*.exs"]) in [:ok, :noop]
    :ok
  end

  setup(%{line: line} = _context) do
    cmd_out_file = @cmd_out_prefix <> Integer.to_string(line) <> ".log"
    cmd_err_file = @cmd_err_prefix <> Integer.to_string(line) <> ".log"
    {:ok, %{cmd_out: cmd_out_file, cmd_err: cmd_err_file}}
  end

  test "pipeline from :stdin to file works",
       %{cmd_out: cmd_out, cmd_err: cmd_err} = _context do
    on_exit(fn -> Logger.debug(File.read!(cmd_err)) end)

    assert {"", _rc = 0} ==
             System.shell(
               "bash -c '                                                                              \
                set -o pipefail;                                                                       \
                cat #{@input_text_file} | mix run test/fixtures/pipe_to_file.exs #{cmd_out} 2048'     \
                2> #{cmd_err}",
               env: [{"MIX_QUIET", "true"}, {"MIX_ENV", "dev"}]
             )

    assert "0123456789" == File.read!(cmd_out)
  end

  test "pipeline from :stdin to file works when content is longer than chunk_size",
       %{cmd_out: cmd_out, cmd_err: cmd_err} = _context do
    on_exit(fn -> Logger.debug(File.read!(cmd_err)) end)

    assert {"", _rc = 0} ==
             System.shell(
               "bash -c '                                                                              \
                set -o pipefail;                                                                       \
                cat #{@input_text_file} | mix run test/fixtures/pipe_to_file.exs #{cmd_out} 5'        \
                2> #{cmd_err}",
               env: [{"MIX_QUIET", "true"}, {"MIX_ENV", "dev"}]
             )

    assert "0123456789" == File.read!(cmd_out)
  end

  test "pipeline from file to :stdout works",
       %{cmd_err: cmd_err} = _context do
    on_exit(fn -> Logger.debug(File.read!(cmd_err)) end)

    assert {"0123456789", _rc = 0} ==
             System.shell("mix run test/fixtures/file_to_pipe.exs #{@input_text_file} \
                           2> #{cmd_err}",
               env: [{"MIX_QUIET", "true"}, {"MIX_ENV", "dev"}]
             )
  end

  test ":stdin/:stdout pipelines work in conjunction",
       %{cmd_out: cmd_out, cmd_err: cmd_err} = _context do
    on_exit(fn -> Logger.debug(File.read!(cmd_err)) end)

    assert {"", _rc = 0} ==
             System.shell(
               "bash -c '                                                                              \
                set -o pipefail;                                                                       \
                mix run test/fixtures/file_to_pipe.exs #{@input_text_file}                             \
                | mix run test/fixtures/pipe_to_file.exs #{cmd_out} 2048'                             \
                2> #{cmd_err}",
               env: [{"MIX_QUIET", "true"}, {"MIX_ENV", "dev"}]
             )

    assert "0123456789" == File.read!(cmd_out)
  end
end
