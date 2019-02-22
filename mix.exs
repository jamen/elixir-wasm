defmodule Wasm.Mixfile do
  use Mix.Project

  def project do
    [app: :wasm,
     description: "WASM compiler for Elixir",
     version: "0.2.0",
     elixir: "~> 1.1-dev",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: "https://github.com/jamen/elixir-wasm",
     deps: deps(),
     package: package()
    ]
  end

  defp deps do
    [{:ex_doc, "~> 0.19", only: :dev}]
  end

  defp package do
    [name: :wasm,
     maintainers: ["Jamen Marz (https://git.io/jamen)"],
     licenses: ["MIT"],
     links: %{ "GitHub" => "https://github.com/jamen/elixir-wasm" }]
  end
end
