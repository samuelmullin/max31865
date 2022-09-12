defmodule Max31865.Server do
  use GenServer
  require Logger

  alias Circuits.SPI
  alias Max31865.Conversions
  alias Max31865.Registers.ConfigRegister


  @moduledoc """
  Driver for the MAX31865 thermocouple amplifier for use on a Raspberry Pi.  Tested with the Raspberry Pi Zero W V 1.2.  Should work similarly with other Raspberry PI devices.

  rtd_nominal: The expected resistance of the RTD at 0 degrees C
  ref_resistor: The resistance of the reference resistor.  Defaults to 430.0 for use with the PT100.  Set to 4300.0 for the PT1000.
  spi_device: The SPI device being used. Defaults to 0.
  spi_device_cs_pin: The CS pin for the SPI device being used.  Defaults to 0.
  rtd_wires: Whether 3 wire mode should be enabled.  Defaults to false for use in 2/4 wire mode.  Set to true for use in 3 wire mode.
  """

  defstruct rtd_nominal: 100,
            ref_resistor: 430.0,
            spi_device: 0,
            spi_device_cs_pin: 0,
            rtd_wires: 4,
            auto_convert: false,
            filter_select_mode: 60,
            max_ref: nil,
            name: __MODULE__


  @type t() :: %__MODULE__{
    rtd_nominal: integer(),
    ref_resistor: float(),
    spi_device: integer(),
    spi_device_cs_pin: integer(),
    rtd_wires: integer(),
    auto_convert: boolean(),
    filter_select_mode: integer(),
    name: atom(),
    max_ref: any() | nil
  }

  # --- Public API ---
  def start_link(config) do
    name = Keyword.get(config, :name, __MODULE__)
    GenServer.start_link(__MODULE__, config, name: name)
  end

  @doc """
    Returns the temperature in degrees celcius.  The result is calculated mathematically using the formula found in the datasheet:
    https://datasheets.maximintegrated.com/en/ds/MAX31865.pdf

  """
  def get_temp(name \\ __MODULE__), do: GenServer.call(name, :get_temp)
  def get_resistance(name \\ __MODULE__), do: GenServer.call(name, :get_resistance)
  def get_config(name \\ __MODULE__), do: GenServer.call(name, :read_config_register)
  def get_max_ref(name \\ __MODULE__), do: GenServer.call(name, :get_max_ref)

  @impl true
  def init(config) do
    server = struct(__MODULE__, config)

    # Open SPI connection
    {:ok, max_ref} = SPI.open("spidev#{server.spi_device}.#{server.spi_device_cs_pin}", mode: 1, speed_hz: 500_000)

    server = struct(server, max_ref: max_ref)

    server
    |> server_to_register()
    |> ConfigRegister.write(server.max_ref)

    {:ok, server}
  end

  @impl true
  def handle_call(:get_temp, _from, server) do
    temp = Conversions.get_temp(server)

    {:reply, temp, server}
  end

  @impl true
  def handle_call(:get_max_ref, _from, server) do
    {:reply, server.max_ref, server}
  end

  @impl true
  def handle_call(:read_config_register, _from, server) do
    response = ConfigRegister.read(server.max_ref)
    {:reply, response, server}
  end

  @impl true
  def handle_call(:get_resistance, _from, server) do
    resistance = Conversions.get_resistance(server)

    {:reply, resistance, server}
  end

  defp server_to_register(%__MODULE__{} = server) do
    conversion_mode = case server.auto_convert do
      true -> 1
      false -> 0
    end

    three_wire = case server.rtd_wires do
      2 -> 0
      3 -> 1
      4 -> 0
    end

    filter_select = case server.filter_select_mode do
      50 -> 1
      60 -> 0
    end

    %ConfigRegister{
      vbias: conversion_mode,
      conversion_mode: conversion_mode,
      three_wire: three_wire,
      filter_select: filter_select
    }
  end

end
