defmodule Max31865 do
  @moduledoc """
    Driver for the MAX31865 thermocouple amplifier for use on a Raspberry Pi.
  """

  @doc"""
    Returns the calculated temperature of the connected RTD in degrees celcius.  Accepts a Server name (in case multiple Max31865 modules are connected), but defaults to the module name if none is set.
  """
  defdelegate get_temp(server_name \\ Max31865.Server), to: Max31865.Server

  @doc"""
    Returns the resistance of the connected RTD.  Accepts a Server name (in case multiple Max31865 modules are connected), but defaults to the module name if none is set.
  """
  defdelegate get_resistance(server_name \\ Max31865.Server), to: Max31865.Server
end
