defmodule Membrane.File.Plugin.Mixfile do
  use Mix.Project

  @version "0.16.0"

  @github_url "https://github.com/membraneframework/membrane_file_plugin"

  def project do
    [
      app: :membrane_file_plugin,
      version: @version,
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),

      # hex
      description: "Plugin for reading and writing to files for Membrane Multimedia Framework",
      package: package(),

      # docs
      name: "Membrane File plugin",
      source_url: @github_url,
      homepage_url: "https://membraneframework.org",
      docs: docs()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp deps do
    [
      {:membrane_core, "~> 1.0"},
      {:logger_backends, "~> 1.0"},
      # Testing
      {:mox, "~> 1.0", only: :test},
      # Development
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false}
    ]
  end

  defp dialyzer() do
    opts = [
      flags: [:error_handling]
    ]

    if System.get_env("CI") == "true" do
      # Store PLTs in a directory cacheable on CI
      File.mkdir_p!(Path.join([__DIR__, "priv", "plts"]))
      [plt_local_path: "priv/plts", plt_core_path: "priv/plts"] ++ opts
    else
      opts
    end
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @github_url,
        "Membrane Framework Homepage" => "https://membraneframework.org"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "LICENSE"],
      formatters: ["html"],
      source_ref: "v#{@version}",
      nest_modules_by_prefix: [Membrane.File]
    ]
  end
end

# Also, a small bug noticed when reproducing on elixir 1.16.0, this time related to mix:
# ```elixir
# require Logger

# Mix.start()
# Mix.shell(Mix.Shell.Quiet)

# Mix.install(
#   [
#     :ratio,
#     :logger_backends
#   ],
#   force: true
# )
# ```
# ```command
# root@5da670a83b2e:/workspace/membrane/logger_mre# elixirc mre.exs 2> stderr.log
# ==> ratio
# ```
# stderr.log:
# ```log
# Every 2.0s: cat stderr.log                                                       5da670a83b2e: Tue Jan 30 12:35:47 2024

#     warning: Ratio.DecimalConversion.decimal_to_rational/1 is undefined (module Ratio.DecimalConversion is not availabl
# e or is yet to be defined)
#     │
#  17 │     {ratio, Ratio.DecimalConversion.decimal_to_rational(decimal)}
#     │                                     ~
#     │
#     └─ lib/ratio/coerce.ex:17:37: Coerce.Implementations.Ratio.Decimal.coerce/2

# both :extra_applications and :applications was found in your mix.exs. You most likely want to remove the :applications
# key, as all applications are derived from your dependencies
# ```
# It looks like a part of the message is logged to stderr, and the last line to stdout, which, again, was a hindrance for our use case.
