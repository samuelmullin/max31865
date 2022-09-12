defmodule Max31865.Registers.RTDResistanceRegister do
  @moduledoc """
  The config register for the MAX31865 consists of 8 bits, from left to right.  The first four are settings:

  - The first 15 bits represent the ratio of RTD resistance to reference resistance
  - The 16th bit is the Fault bit: 0 if no faults were detected, 1 if faults were detected.

  """

  alias Circuits.SPI

  @read_register <<0x01>>

  def read(max_ref) do
    {:ok, <<0x00, raw_reading::size(15), fault_bit::size(1)>>} = SPI.transfer(max_ref, <<@read_register::binary, 0x00, 0x00>>)
    case fault_bit do
      1 -> {:error, :read_fault}
      0 -> {:ok, raw_reading}
    end
  end


end
