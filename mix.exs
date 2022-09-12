defmodule Max31865.MixProject do
  use Mix.Project

  def project do
    [
      app: :max31865,
      version: "0.1.0",
      elixir: "~> 1.13",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
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
      {:circuits_spi, "~> 1.3"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md": [
          title: "Readme"
        ]
      ]
    ]
  end

  defp package do
    [
      name: "max31865",
      description:
        "A driver for working with the Max31865 RTD amplifier and a PT100 or PT1000.  Still a WIP but probably perfectly fine for most hobbyist needs.",
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/samuelmullin/max31865"}
    ]
  end
end
