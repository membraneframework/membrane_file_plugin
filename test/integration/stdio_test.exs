defmodule Membrane.File.Integration.StdioTest do
  use ExUnit.Case, async: false
  require Logger

  # 5min if dev env needs to compile
  @moduletag timeout: 360_000
  @moduletag :tmp_dir
  @moduletag :long_running

  @input_text_file "test/fixtures/input.txt"
  @file_to_pipe "examples/file_to_pipe.exs"
  @pipe_to_file "examples/pipe_to_file.exs"

  test "pipeline from :stdin to file works",
       %{tmp_dir: tmp_dir} = _context do
    cmd_out = Path.join([tmp_dir, "out.txt"])
    pipeline_err = Path.join([tmp_dir, "err.txt"])

    {output, rc} =
      System.shell(
        """
        bash -c '
              set -o pipefail;
              cat #{@input_text_file} | elixir #{@pipe_to_file} #{cmd_out} 2048'
              2> #{pipeline_err}
        """
        |> String.replace("\n", "")
      )

    Logger.debug("output when running script:")
    Logger.debug(output)
    Logger.debug("--- end output ---")

    assert rc == 0 and
             "0123456789" == File.read!(cmd_out),
           """
           Outputs did not match, see pipeline's stderr:
           #{pipeline_err}
           """
  end

  test "pipeline from :stdin to file works when content is longer than chunk_size",
       %{tmp_dir: tmp_dir} = _context do
    cmd_out = Path.join([tmp_dir, "out.txt"])
    pipeline_err = Path.join([tmp_dir, "err.txt"])

    {output, rc} =
      System.shell(
        """
        bash -c '
              set -o pipefail;
              cat #{@input_text_file} | elixir #{@pipe_to_file} #{cmd_out} 5'
              2> #{pipeline_err}
        """
        |> String.replace("\n", "")
      )

    Logger.debug("output when running script:")
    Logger.debug(output)
    Logger.debug("--- end output ---")

    assert rc == 0 and
             "0123456789" == File.read!(cmd_out),
           """
           Outputs did not match, see pipeline's stderr:
           #{pipeline_err}
           """
  end

  test "pipeline from file to :stdout works",
       %{tmp_dir: tmp_dir} = _context do
    pipeline_err = Path.join([tmp_dir, "err.txt"])

    assert {"0123456789", _rc = 0} ==
             System.shell("elixir #{@file_to_pipe} #{@input_text_file} 2> #{pipeline_err}"),
           """
           Outputs did not match, see pipeline's stderr:
           #{pipeline_err}
           """
  end

  test "file to :stdout to :stdin to file works",
       %{tmp_dir: tmp_dir} = _context do
    cmd_out = Path.join([tmp_dir, "out.txt"])
    pipeline1_err = Path.join([tmp_dir, "err1.txt"])
    pipeline2_err = Path.join([tmp_dir, "err2.txt"])

    {output, rc} =
      System.shell(
        """
        bash -c '
                set -o pipefail;
                elixir #{@file_to_pipe} #{@input_text_file} 2> #{pipeline1_err}
              | elixir #{@pipe_to_file} #{cmd_out} 2048'    2> #{pipeline2_err}
        """
        |> String.replace("\n", "")
      )

    Logger.debug("output when running script:")
    Logger.debug(output)
    Logger.debug("--- end output ---")

    assert rc == 0 and
             "0123456789" == File.read!(cmd_out),
           """
           Outputs did not match, see pipelines' stderr:
           #{pipeline1_err}
           #{pipeline2_err}
           """
  end
end
