defmodule Max31865.Registers.FaultThresholdRegister do
  @moduledoc """

  Allows the reading and writing of the Max31865 Fault Threshold Register.

  ## Register Layout

  Each fault threshold register consists of 16-bits of data which represent an integer.  That integer is used to determine if a reading is higher or lower than is allowed.any()

  The default state for the low registers is 0, the default state for the high registers is 65,535.
  """
  alias Circuits.SPI

  @high_fault_threshold_read_register <<0x03>>
  @low_fault_threshold_read_register <<0x05>>
  @high_fault_threshold_write_register <<0x83>>
  @low_fault_threshold_write_register <<0x85>>

  @doc"""
  Read a fault threshold register.

  Parameters:

    - `:high`/`:low` which signify whether the register contains the high threshold or low threshold
    - `:max_ref` which is a reference to a Max31865 SPI Connection

    Returns a tuple of `{:ok, threshold}` where threshold integer representing the current value the requested register.
  """
  def read(:high, max_ref), do: read_register(@high_fault_threshold_read_register, max_ref)
  def read(:low, max_ref), do: read_register(@low_fault_threshold_read_register, max_ref)

  defp read_register(register, max_ref) do
    {:ok, <<0x00, threshold::size(16)>>} = SPI.transfer(max_ref, <<register::binary, 0x00, 0x00>>)
    {:ok, threshold}
  end

  @doc"""
  Write to a fault threshold register.

  Paramaters:

    - `:high`/`:low` which signify whether the register contains the high threshold or low threshold
    - An integer representing the new threshold
    - `:max_ref` which is a reference to a Max31865 SPI Connection

    Returns a tuple of `{:ok, value}` where value is the new threshold written to the requested register.
  """
  def write(:high, threshold, max_ref), do: write_register(@high_fault_threshold_write_register, threshold, max_ref)
  def write(:low, threshold, max_ref), do: write_register(@low_fault_threshold_write_register, threshold, max_ref)

  defp write_register(register, threshold, max_ref) do
    threshold = encode_threshold(threshold)
    {:ok, <<0x00, 0x00, 0x00>>} = SPI.transfer(max_ref, <<register::binary, threshold::binary>>)
    {:ok, threshold}
  end

  defp encode_threshold(threshold) when threshold < 0, do: raise("Fault threshold must be above 0")
  defp encode_threshold(threshold) when threshold <= 255, do: <<0x00, :binary.encode_unsigned(threshold)>>
  defp encode_threshold(threshold) when threshold <= 65535, do: :binary.encode_unsigned(threshold)
  defp encode_threshold(_threshold), do: raise("Fault threshold must be less than or equal to 65535")
end
