defmodule WASM.Mixfile do
  use Mix.Project

  def project do
    [app: :wasm,
     version: "0.0.1",
     elixir: "~> 1.1-dev",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: "https://github.com/jamen/elixir-wasm",
     deps: deps(),
     package: package()]
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
  #:
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [{:varint, github: "jamen/varint", branch: "signed-leb128"}]
  end

  defp package do
    [name: :wasm,
     maintainers: ["Jamen Marz (https://git.io/jamen)"],
     licenses: ["MIT"],
     links: %{ "GitHub" => "https://github.com/jamen/elixir-wasm" }]
  end
end
