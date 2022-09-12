defmodule Max31865.Registers.RTDResistanceRegister do
  @moduledoc """

  Allows the reading of the Max31865 RTD Resistance Register.

  ## Register Layout

  - The first 15 bits represent the ratio of RTD resistance to reference resistance
  - The 16th bit will be set if the value returned was higher or lower than the values defined in the [Fault Threshold Register](`Max31865.Registers.FaultThresholdRegister`)
  """

  alias Circuits.SPI

  @read_register <<0x01>>

  @doc"""
  Get a raw reading from the RTD resistance register.

  If the reading was within the bounds set in the [Fault Threshold Register](`Max31865.Registers.FaultThresholdRegister`), returns `{:ok, reading}`, where reading is a 15-bit integer.

  If the reading was outside those bounds, returns `{:error, :read_threshold_fault}`
  """
  def read(max_ref) do
    {:ok, <<0x00, raw_reading::size(15), fault_bit::size(1)>>} = SPI.transfer(max_ref, <<@read_register::binary, 0x00, 0x00>>)
    case fault_bit do
      1 -> {:error, :read_threshold_fault}
      0 -> {:ok, raw_reading}
    end
  end


end
