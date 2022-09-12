defmodule Max31865.Registers.ConfigRegister do
  @moduledoc """

  Allows the reading and writing of the Max31865 Config Register.

  ## Register Layout

  The config register for the MAX31865 consists of 8 bits, from left to right:

  |Vbias|AutoMode|OneShotMode|ThreeWireMode|FaultCycle1|FaultCycle2|Fault Clear|Filter Select|
  |-----|---------|-----------|------|-------------|-------------|-----------|-------------|

  |Name           |R/W |Behaviour                                                      |
  |---------------|----|---------------------------------------------------------------|
  |Vbias          |R/W | Enables/Disables Vbias.  Vbias introduces self heating so it should be disabled when not actively performing conversions.|
  |AutoMode       |R/W | When enabled, conversions will be performed constantly even if they are not being read.  Vbias *must* be enabled if auto mode is enabled.|
  |OneShotMode    |R/W | When enabled a single conversion is performed, after which the bit is automatically cleared.|
  |ThreeWireMode  |R/W | When enabled, three wire mode is used.  Otherwise, 2/4 wire mode is used.|
  |FaultCycle1    |R   | Used to determine fault cycle status.  See below for further detail.|
  |FaultCycle2    |R   | Used to determine fault cycle status.  See below for further detail.|
  |FaultClear     |R/W | When enabled, any faults will be cleared, after which the bit is automatically cleared.|
  |FilterSelect   |R/W | Used to filter out mains noise.  When enabled, 50hz mode is used.  Otherwise, 60hz mode is used.|


  ## Fault Cycle Status Bits

  The Fault Cycle bits can be written to in order to trigger a fault detection with either an automatic or manual delay.  In the case of a manual delay, fault detection continues until the user requests that it ends.

  The Fault Cycle bits can be read to determine the status of the Fault Cycle.  Note that these bits do not report faults.  For that, see the FaultRegister.

  ### Writing to Fault Cycle Bits

  |Bit 1|Bit 2|Meaning                                             |
  |-----|-----|----------------------------------------------------|
  |0    |0    |N/A|
  |1    |0    |Begin Fault detection with Automatic completion|
  |0    |1    |Begin Fault detection with Manual completion|
  |1    |1    |End Fault detection with Manual completion|

  ### Reading from Fault Cycle Bits

  |Bit 1|Bit 2|Meaning                                             |
  |-----|-----|----------------------------------------------------|
  |0    |0    |Fault detection finished|
  |1    |0    |Automatic fault detection still running|
  |0    |1    |Manual cycle 1 still running; waiting for user to write 11|
  |1    |1    |Manual cycle 2 still running|

  """

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

  @doc"""
  Accepts a Max31865 SPI reference and reads the Config Register, then returns a ConfigRegister struct representing it's contents.
  """
  def read(max_ref) do
    {:ok, <<@read_register, bits>>} = SPI.transfer(max_ref, <<@read_register::binary, 0x00>>)
    to_struct(<<bits>>)
  end

  @doc"""
  Accepts a ConfigRegister struct and a Max31865 SPI reference and writes it to the ConfigRegister.
  """
  def write(%__MODULE__{} = config, max_ref) do
    {:ok, response} = SPI.transfer(max_ref, <<@write_register::binary, to_bits(config)::binary>>)
    response
  end

  defp to_bits(%__MODULE__{} = config) do
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

  defp to_struct(<<_::size(8)>> = bits) do
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

end
