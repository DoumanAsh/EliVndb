defmodule EliVndb.Mixfile do
  use Mix.Project

  @description """
  Kawaii VNDB API wrapper.
  """

  def project do
    [app: :elivndb,
     version: "0.2.3",
     elixir: "~> 1.4",
     description: @description,
     package: package(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),

     # Docs
     name: "EliVndb",
     docs: [main: "EliVndb",
            extras: ["README.md"]]
    ]
  end

  def application do
    [extra_applications: [:logger, :ssl]]
  end

  defp deps do
    [
      {:poison, "~> 3.1"},
      {:credo, "~> 0.7", only: [:dev, :test]},
      {:ex_doc, "~> 0.15", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false}
    ]
  end

  defp package do
    [ maintainers: ["Douman"],
      files: ~w(lib mix.exs README.md LICENSE),
      licenses: ["MIT"],
      links: %{ "Github" => "https://github.com/DoumanAsh/EliVndb" } ]
  end
end
