defmodule Single.MixProject do
  use Mix.Project

  @version "0.2.0"

  def project do
    [
      app: :single,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Runs supervised, singleton processes within an Erlang cluster.",
      package: [
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/balexand/single"}
      ],
      docs: [
        extras: ["README.md"],
        source_ref: "v#{@version}",
        source_url: "https://github.com/balexand/single"
      ]
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
      # Dev/test
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
