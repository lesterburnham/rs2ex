defmodule Rs2ex.MixProject do
  use Mix.Project

  def project do
    [
      app: :rs2ex,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Rs2ex, []},
      extra_applications: [:logger, :ranch]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ranch, "~> 1.8"},
      {:isaac, "~> 0.0.1"}
    ]
  end
end
