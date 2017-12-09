defmodule Concern.Mixfile do
  use Mix.Project

  def project do
    [
      app: :concern,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      package: package(),
      description: description()
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
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md"],
      maintainers: ["Aetherus Zhou"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/Aetherus/concern"
      }
    ]
  end

  defp description do
    "Bring ActiveSupport::Concern to Elixir world"
  end
end
