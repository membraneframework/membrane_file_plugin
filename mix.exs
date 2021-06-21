defmodule Membrane.File.Plugin.Mixfile do
  use Mix.Project

  @version "0.6.0"
  @github_url "https://github.com/membraneframework/membrane_file_plugin"

  def project do
    [
      app: :membrane_file_plugin,
      compilers: Mix.compilers(),
      version: @version,
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      description: "Membrane plugin for reading and writing to files",
      package: package(),
      name: "Membrane File plugin",
      source_url: @github_url,
      docs: docs(),
      deps: deps()
    ]
  end

  def application do
    [extra_applications: []]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v#{@version}"
    ]
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => @github_url,
        "Membrane Framework Homepage" => "https://membraneframework.org"
      }
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:membrane_core, "~> 0.7.0"},
      {:mockery, "~> 2.2", runtime: false}
    ]
  end
end
