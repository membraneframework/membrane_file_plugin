defmodule Membrane.Element.File.Mixfile do
  use Mix.Project

  def project do
    [
      app: :membrane_element_file,
      compilers: Mix.compilers(),
      version: "0.0.1",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      description: "Membrane Multimedia Framework (File Element)",
      maintainers: ["Membrane Team"],
      licenses: ["Apache 2.0"],
      name: "Membrane Element: File",
      source_url: "https://github.com/membraneframework/membrane-element-file",
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [], mod: {Membrane.Element.File, []}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:membrane_core, git: "git@github.com:membraneframework/membrane-core.git"},
      {:mockery, "~> 2.1", runtime: false}
    ]
  end
end
