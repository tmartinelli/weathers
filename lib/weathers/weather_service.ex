defmodule Weathers.WeatherService do
  require Logger
  require Record

  Record.defrecord :xmlElement, Record.extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlText, Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")

  @national_weather_service_url Application.get_env(:weathers, :national_weather_service_url)

  @fields [
    {:location, :location},
    {:observation_time, :updated_at},
    {:weather, :weather},
    {:temperature_string, :temperature}
  ]

  def fetch_for(location) do
    Logger.info("Fetching weather data for #{location}...")
    location
    |> weather_url
    |> HTTPoison.get
    |> handle_response
  end

  def weather_url(location) do
    upcased_location = String.upcase(location)
    "#{@national_weather_service_url}/xml/current_obs/#{upcased_location}.xml"
  end

  def handle_response({ :ok, %{ status_code: 200, body: body } }) do
    Logger.info("Success response")
    Logger.debug(fn -> inspect(body) end)
    { :ok, handle_body(body) }
  end

  def handle_response({ _, %{ status_code: 404, body: body } }) do
    Logger.info("Not found response")
    { :not_found, body }
  end

  def handle_response({ _, %{ status_code: status, body: body } }) do
    Logger.error "Error #{status} returned"
    { :error, body }
  end

  defp handle_body(body) do
    body
    |> get_field_values
    |> prepare_response
  end

  defp get_field_values(body), do: @fields |> Enum.map(&(get_field_value(body, &1)))

  defp get_field_value(body, {service_field, field}) do
    { xml, _rest } = body |> String.to_char_list |> :xmerl_scan.string
    [element] = data_path(service_field) |> :xmerl_xpath.string(xml)
    [text]     = xmlElement(element, :content)
    value      = xmlText(text, :value) |> to_string
    { field, value }
  end

  defp data_path(field), do: "/current_observation/#{to_string(field)}" |> String.to_char_list

  defp prepare_response(weather_data), do: _prepare_response(weather_data, %{})

  defp _prepare_response([], result), do: result

  defp _prepare_response([ head | tail ], result), do: _prepare_response(tail, Map.put(result, elem(head, 0), elem(head, 1)))
end
