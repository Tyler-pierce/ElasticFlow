defmodule ElasticFlow.Mixfile do
  use Mix.Project

  def project do
    [
      app: :elastic_flow,
      version: "0.0.1",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      description: description(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      env: [],
      mod: {ElasticFlow.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:flow, "~> 0.13"},
      {:msgpax, "~> 2.0"},
      {:timex, ">= 3.1.0"},
      {:hashids, "~> 2.0"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "Computational distributable flows with stages inspired by Flow, Spark and EMR."
  end

  defp package() do
    [
      licenses: ["MIT"],
      maintainers: ["Tyler Pierce"],
      files: ["lib", "mix.exs", "README.md", "test", "config"],
      links: %{"GitHub" => "https://github.com/Tyler-pierce/ElasticFlow"},
      source_url: "https://github.com/Tyler-pierce/ElasticFlow"
    ]
  end
end
