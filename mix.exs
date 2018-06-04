defmodule Membrane.Element.File.Mixfile do
  use Mix.Project

  def project do
    [
      app: :membrane_element_file,
      compilers: Mix.compilers(),
      version: "0.1.0",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      description: "Membrane Multimedia Framework (File Element)",
      package: package(),
      name: "Membrane Element: File",
      source_url: link(),
      homepage_url: "https://membraneframework.org",
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [], mod: {Membrane.Element.File, []}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp link do
    "https://github.com/membraneframework/membrane-element-file"
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => link()}
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.18", only: :dev, runtime: false},
      {:membrane_core, git: "git@github.com:membraneframework/membrane-core.git"},
      {:mockery, "~> 2.1", runtime: false}
    ]
  end
end
