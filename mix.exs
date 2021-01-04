defmodule Base85.MixProject do
  use Mix.Project

  def project do
    [
      app: :base85,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Base85",
      description: "Implements some base-85 character encodings.",
      source_url: "https://github.com/jvantuyl/base85",
      homepage_url: "https://github.com/jvantuyl/base85",
      package: [licenses: ["MIT"], links: %{"GitHub" => "https://github.com/jvantuyl/base85"}],
      docs: [main: "Base85"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.23", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
