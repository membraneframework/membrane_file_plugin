defmodule Membrane.File.Integration.StdioTest do
  use ExUnit.Case, async: false
  require Logger

  # 5min if dev env needs to compile
  @moduletag timeout: 360_000
  @moduletag :tmp_dir

  @input_text_file "test/fixtures/input.txt"

  setup_all(_context) do
    assert Mix.Task.run("compile", ["test/fixtures/*.exs"]) in [:ok, :noop]
    :ok
  end

  setup(%{tmp_dir: tmp_dir} = _context) do
    cmd_out_file = Path.join(tmp_dir, "out.txt")
    Logger.debug("cmd_out_file=#{cmd_out_file}")
    cmd_err_file = Path.join(tmp_dir, "err.txt")
    Logger.debug("cmd_err_file=#{cmd_err_file}")
    {:ok, %{cmd_out: cmd_out_file, cmd_err: cmd_err_file}}
  end

  test "pipeline from :stdin to file works",
       %{cmd_out: cmd_out, cmd_err: cmd_err} = _context do
    {output, rc} =
      System.shell(
        "bash -c '                                                                                   \
                set -o pipefail;                                                                     \
                cat #{@input_text_file} | mix run test/fixtures/pipe_to_file.exs #{cmd_out} 2048'    \
                2> #{cmd_err}",
        # MIX_ENV set explicitly to dev so that file_behaviour is not mocked
        env: [{"MIX_QUIET", "true"}, {"MIX_ENV", "dev"}]
      )

    Logger.debug("output when running script:\n#{output}\nendoutput")

    assert output == "" and
             rc == 0 and
             "0123456789" == File.read!(cmd_out),
           File.read!(cmd_err)
  end

  test "pipeline from :stdin to file works when content is longer than chunk_size",
       %{cmd_out: cmd_out, cmd_err: cmd_err} = _context do
    {output, rc} =
      System.shell(
        "bash -c '                                                                                   \
                set -o pipefail;                                                                     \
                cat #{@input_text_file} | mix run test/fixtures/pipe_to_file.exs #{cmd_out} 5'       \
                2> #{cmd_err}",
        env: [{"MIX_QUIET", "true"}, {"MIX_ENV", "dev"}]
      )

    assert output == "" and
             rc == 0 and
             "0123456789" == File.read!(cmd_out),
           File.read!(cmd_err)
  end

  test "pipeline from file to :stdout works",
       %{cmd_err: cmd_err} = _context do
    assert {"0123456789", _rc = 0} ==
             System.shell("mix run test/fixtures/file_to_pipe.exs #{@input_text_file} \
                           2> #{cmd_err}",
               env: [{"MIX_QUIET", "true"}, {"MIX_ENV", "dev"}]
             ),
           File.read!(cmd_err)
  end

  test ":stdin/:stdout pipelines work in conjunction",
       %{cmd_out: cmd_out, cmd_err: cmd_err} = _context do
    {output, rc} =
      System.shell(
        "bash -c '                                                                                   \
                set -o pipefail;                                                                     \
                mix run test/fixtures/file_to_pipe.exs #{@input_text_file}                           \
                | mix run test/fixtures/pipe_to_file.exs #{cmd_out} 2048'                            \
                2> #{cmd_err}",
        env: [{"MIX_QUIET", "true"}, {"MIX_ENV", "dev"}]
      )

    assert output == "" and
             rc == 0 and
             "0123456789" == File.read!(cmd_out),
           File.read!(cmd_err)
  end
end
