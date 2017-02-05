defmodule Weathers.CLI do

  @moduledoc """
  Command line program which fetches data about weather in a location passed as argument
  """

  def main(argv) do
    argv
    |> parse_args
    |> process
  end

  def parse_args(argv) do
    parse = OptionParser.parse(argv, switches: [help: :boolean], aliases: [h: :help])

    case parse do
      {[help: true], _, _} -> :help
      {_, [location], _} -> { location }
      _ -> :help
    end
  end

  def process(:help) do
    IO.puts("usage: weathers <location>")
    System.halt(0)
  end

  def process({ location }) do
    location
    |> Weathers.WeatherService.fetch_for
    |> print_weather

    System.halt(2)
  end

  def print_weather({ _, weather }) do
    IO.puts("Weather Infos")
    IO.puts("Location: #{weather[:location]}")
    IO.puts(weather[:updated_at])
    IO.puts("Weather: #{weather[:weather]}")
    IO.puts("Temperature: #{weather[:temperature]}")
  end
end
