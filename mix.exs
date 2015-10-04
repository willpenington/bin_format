defmodule BinFormat.Mixfile do
  use Mix.Project

  def project do
    [app: :bin_format,
     version: "0.0.1",
     elixir: "~> 1.0",
     source_url: "https://github.com/willpenington/binstructor",
     docs: [extras: ["README.md"]],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description,
     package: package,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [{:earmark, "~> 0.1", only: :dev},
     {:ex_doc, "~> 0.10", only: :dev}]
  end

  defp description do
    """
    Automatically generate the boilerplate to convert between binaries and
    Elixir structs.
    """
  end

  defp package do
    [maintainers: ["Will Penington"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/willpenington/bin_format"}]
  end

end
