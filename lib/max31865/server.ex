defmodule Max31865.Server do
  use GenServer

  alias Circuits.SPI
  alias Max31865.Conversions
  alias Max31865.Registers.ConfigRegister


  @moduledoc """
  Server to interact with Max31865 connected via SPI.

  ## Config options

  - rtd_nominal: The expected resistance of the RTD at 0 degrees C.  Typically 100.
  - ref_resistor: The resistance of the reference resistor.  Defaults to 430.0 for use with the PT100.  Set to 4300.0 for the PT1000.
  - spi_device: The SPI device being used. Defaults to 0.
  - spi_device_cs_pin: The CS pin for the SPI device being used.  Defaults to 0.
  - rtd_wires: Whether 3 wire mode should be enabled.  Defaults to false for use in 2/4 wire mode.  Set to true for use in 3 wire mode.
  - auto_convert:  Whether auto-conversion mode should be used - if true, the module will constantly measure resistance.  This introduces self heating as it requires the VBias to be enabled constantly, so unless you have a particular need for it, using one shot measurements is recommended.
  - filter_select_mode: Determines whether to filter for 50hz or 60hz noise from the mains.  If you live in North America, the default (60) will work.

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

  @doc"""
  Returns the temperature in degrees celcius.  The result is calculated mathematically using the formula found in the datasheet:
  https://datasheets.maximintegrated.com/en/ds/MAX31865.pdf
  """
  def get_temp(name \\ __MODULE__), do: GenServer.call(name, :get_temp)

  @doc"""
  Returns the resistance calculated from the RTD.
  """
  def get_resistance(name \\ __MODULE__), do: GenServer.call(name, :get_resistance)

  @doc"""
  Returns a [Config Register](`Max31865.Registers.ConfigRegister`) struct with the current contents of the register.
  """
  def get_config(name \\ __MODULE__), do: GenServer.call(name, :get_config)

  @doc"""
  Clears any faults set in the [Fault Register](`Max31865.Registers.FaultRegister`).
  """
  def clear_faults(name \\ __MODULE__), do: GenServer.call(name, :clear_fault_register)

  @doc"""
  Returns the reference to the SPI connection that was opened for this Server.
  """
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
  def handle_call(:get_config, _from, server) do
    response = ConfigRegister.read(server.max_ref)
    {:reply, response, server}
  end

  @impl true
  def handle_call(:get_resistance, _from, server) do
    resistance = Conversions.get_resistance(server)

    {:reply, resistance, server}
  end

  @impl true
  def handle_cast(:clear_fault_register, server) do
    ConfigRegister.read(server.max_ref)
    |> struct([fault_clear: 1])
    |> ConfigRegister.write(server.max_ref)

    {:noreply, server}
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
