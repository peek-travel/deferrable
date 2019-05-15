defmodule Deferrable.MixProject do
  use Mix.Project

  @version "0.0.1"
  @source_url "https://github.com/peek-travel/deferrable"

  def project do
    [
      app: :deferrable,
      version: @version,
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      description: description(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: []
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp docs do
    [
      main: "Deferrable",
      source_ref: @version,
      source_url: @source_url,
      extras: ["README.md", "LICENSE.md"]
    ]
  end

  defp description do
    """
    Library for deferring execution of code until the completion of a transaction block.
    """
  end

  defp package do
    [
      files: ["lib", ".formatter.exs", "mix.exs", "README.md", "LICENSE.md"],
      maintainers: ["Daniel Hedlund <daniel@digitree.org>", "Chris Dosé <chris.dose@gmail.com>"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Readme" => "#{@source_url}/blob/#{@version}/README.md"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.20", only: :dev, runtime: false}
    ]
  end
end
