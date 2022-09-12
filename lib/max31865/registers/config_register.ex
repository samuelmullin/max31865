defmodule Max31865.Registers.ConfigRegister do
  @moduledoc """
  The config register for the MAX31865 consists of 8 bits, from left to right.  The first four are settings:

  - VBias 1: on, 0: off.  This introduces self-heating so it should be disabled when we are not actively reading.  Must be enabled if Conversion mode is set to auto.
  - Conversion Mode 1: Auto, 0: Normally off.   When set to auto, readings will be continuously performed at a rate based on the 50/60Hz filter select.
  - 1Shot mode:  1: on, 0: off (Auto clears after setting 1).  Takes a single reading and resets itself to 0 afterwards.
  - 3 Wire mode:  1: 3 Wire RTD, 0: 2 or 4 Wire RTD.  Should be set to one if the connected RTD uses 3 wires, otherwise set to 0.
  - Fault Detection Cycle Control 1 of 2 (see below)
  - Fault Detection Cycle Control 2 of 2 (see below)
  - Fault Status Clear: 1: Clear, 0: Don't Clear (Auto clears after setting 1).  Clears the fault status and resets itself to 0 afterwards.
  - 50/60Hz Filter Select:  1: 50Hz, 0: 60Hz. Set based on the mains AC frequency for your country.
  """
  require Logger
  alias Circuits.SPI

  @read_register <<0x00>>
  @write_register <<0x80>>


  defstruct vbias: 0,
            conversion_mode: 0,
            one_shot: 0,
            three_wire: 0,
            fault_one: 0,
            fault_two: 0,
            fault_clear: 0,
            filter_select: 0

  def bits(options) do
    config = struct(__MODULE__, options)

    <<
      config.vbias::1,
      config.conversion_mode::1,
      config.one_shot::1,
      config.three_wire::1,
      config.fault_one::1,
      config.fault_two::1,
      config.fault_clear::1,
      config.filter_select::1
    >>
  end

  def to_struct(bits) do
      <<
        vbias::size(1),
        conversion_mode::size(1),
        one_shot::size(1),
        three_wire::size(1),
        fault_one::size(1),
        fault_two::size(1),
        fault_clear::size(1),
        filter_select::size(1)
      >> = bits

      struct(__MODULE__, [
        vbias: vbias,
        conversion_mode: conversion_mode,
        one_shot: one_shot,
        three_wire: three_wire,
        fault_one: fault_one,
        fault_two: fault_two,
        fault_clear: fault_clear,
        filter_select: filter_select
      ])
  end

  def read(max_ref) do
    {:ok, <<@read_register, bits>>} = SPI.transfer(max_ref, <<@read_register::binary, 0x00>>)
    to_struct(<<bits>>)
  end

  def write(%__MODULE__{} = config, max_ref) do
    Logger.info("Config in write: #{inspect(config)}")
    new_config_bits =
      config
      |> Map.from_struct()
      |> bits()

      Logger.info("Bits in write: #{inspect(new_config_bits)}")

    {:ok, response} = SPI.transfer(max_ref, <<@write_register::binary, new_config_bits::binary>>)
    response
  end

end
