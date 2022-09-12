defmodule Max31865.Registers.FaultRegister do

  alias Circuits.SPI

  @read_register <<0x07>>

  defstruct rtd_high_threshold: 0,
            rtd_low_threshold: 0,
            ref_in_low: 0,
            ref_in_high: 0,
            rtd_in_low: 0,
            over_under_voltage: 0

  def to_struct(bits) do
      <<
        rtd_high_threshold::size(1),
        rtd_low_threshold::size(1),
        ref_in_low::size(1),
        ref_in_high::size(1),
        rtd_in_low::size(1),
        over_under_voltage::size(1),
        _::size(2)
      >> = bits

      struct(__MODULE__, [
        rtd_high_threshold: rtd_high_threshold,
        rtd_low_threshold: rtd_low_threshold,
        ref_in_low:  ref_in_low,
        ref_in_high: ref_in_high,
        rtd_in_low: rtd_in_low,
        over_under_voltage: over_under_voltage,
      ])
  end

  def read(max_ref) do
    {:ok, <<0x00, bits>>} = SPI.transfer(max_ref, <<@read_register::binary, 0x00>>)
    to_struct(<<bits>>)
  end

end
