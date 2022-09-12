defmodule Max31865.Registers.FaultThresholdRegister do

  alias Circuits.SPI

  @msb_high_fault_threshold_read_register <<0x03>>
  @lsb_high_fault_threshold_read_register <<0x04>>
  @msb_low_fault_threshold_read_register <<0x05>>
  @lsb_low_fault_threshold_read_register <<0x06>>
  @msb_high_fault_threshold_write_register <<0x83>>
  @lsb_high_fault_threshold_write_register <<0x84>>
  @msb_low_fault_threshold_write_register <<0x85>>
  @lsb_low_fault_threshold_write_register <<0x86>>


  def read(:msb, :high, max_ref), do: read(@msb_high_fault_threshold_read_register, max_ref)
  def read(:lsb, :high, max_ref), do: read(@lsb_high_fault_threshold_read_register, max_ref)
  def read(:msb, :low, max_ref), do: read(@msb_low_fault_threshold_read_register, max_ref)
  def read(:lsb, :low, max_ref), do: read(@lsb_low_fault_threshold_read_register, max_ref)

  defp read(register, max_ref) do
    {:ok, <<0x00, threshold::size(16)>>} = SPI.transfer(max_ref, <<register::binary, 0x00, 0x00>>)
    {:ok, threshold}
  end

  def write(:msb, :high, threshold, max_ref), do: write(@msb_high_fault_threshold_write_register, threshold, max_ref)
  def write(:lsb, :high, threshold, max_ref), do: write(@lsb_high_fault_threshold_write_register, threshold, max_ref)
  def write(:msb, :low, threshold, max_ref), do: write(@msb_low_fault_threshold_write_register, threshold, max_ref)
  def write(:lsb, :low, threshold, max_ref), do: write(@lsb_low_fault_threshold_write_register, threshold, max_ref)

  defp write(register, threshold, max_ref) do
    threshold = encode_threshold(threshold)
    {:ok, <<0x00, 0x00, 0x00>>} = SPI.transfer(max_ref, <<register::binary, threshold::binary>>)
    {:ok, threshold}
  end

  defp encode_threshold(threshold) when threshold < 0, do: raise("Fault threshold must be above 0")
  defp encode_threshold(threshold) when threshold <= 255, do: <<0x00, :binary.encode_unsigned(threshold)>>
  defp encode_threshold(threshold) when threshold <= 65535, do: :binary.encode_unsigned(threshold)
  defp encode_threshold(_threshold), do: raise("Fault threshold must be less than or equal to 65535")
end
