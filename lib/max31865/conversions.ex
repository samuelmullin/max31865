defmodule Max31865.Conversions do

  alias Max31865.Server
  alias Max31865.Registers.{ConfigRegister, RTDResistanceRegister}

  def get_temp(%Server{} = server) do
    get_resistance(server)
    |> temperature_from_resistance(server.rtd_nominal)
  end

  def get_resistance(%Server{} = server) do
    get_raw_reading(server.auto_convert, server.max_ref)
    |> resistance_from_reading(server.ref_resistor)
  end

  defp get_raw_reading(_autoconvert = true, max_ref), do: auto_convert_reading(max_ref)
  defp get_raw_reading(_autoconvert = false, max_ref), do: one_shot_reading(max_ref)


  defp auto_convert_reading(max_ref) do
    {:ok, raw_reading} = RTDResistanceRegister.read(max_ref)
    raw_reading
  end

  defp one_shot_reading(max_ref) do
    # Enable VBias and Clear Faults, then sleep for 10ms as we wait for the capacitors to charge
    ConfigRegister.read(max_ref)
    |> struct([fault_clear: 1, vbias: 1])
    |> ConfigRegister.write(max_ref)

    Process.sleep(10)

    # Set the one shot mode bit.  It will self clear after a conversion completes.
    ConfigRegister.read(max_ref)
    |> struct(one_shot: 1)
    |> ConfigRegister.write(max_ref)

    # A cycle takes 52ms in 60Hz filter mode or 62.5ms in 50Hz filter mode to complete
    Process.sleep(65)

    # Get the reading
    {:ok, raw_reading} = RTDResistanceRegister.read(max_ref)

    # Disable VBias to avoid self heating
    ConfigRegister.read(max_ref)
    |> struct(vbias: 0)
    |> ConfigRegister.write(max_ref)

    raw_reading
  end

  defp resistance_from_reading(reading, ref_resistor) do
    reading / 32768 * ref_resistor
  end

  defp temperature_from_resistance(resistance, rtd_nominal) do
    apply_primary_formula(resistance, rtd_nominal)
    |> apply_alternative_formula(resistance, rtd_nominal)
  end

  defp apply_primary_formula(resistance, rtd_nominal) do
    rtd_a = 3.9083e-3
    rtd_b = -5.775e-7

    z1 = -rtd_a
    z2 = (rtd_a * rtd_a) - (4 * rtd_b)
    z3 = (4 * rtd_b) / rtd_nominal
    z4 = 2 * rtd_b

    temp = z2 + (z3 * resistance)
    (:math.sqrt(temp) + z1) / z4
  end

  defp apply_alternative_formula(temp, _, _) when temp >= 0, do: temp
  defp apply_alternative_formula(_, resistance, rtd_nominal) do
    raw_reading = (resistance / rtd_nominal) * 100
    rpoly = raw_reading
    temp = -242.02 + (2.2228 * rpoly)

    rpoly = rpoly * raw_reading
    temp = temp + (2.5859e-3 * rpoly)

    rpoly = rpoly * raw_reading
    temp = temp - (4.8260e-6 * rpoly)

    rpoly = rpoly * raw_reading
    temp = temp - (2.8183e-8 * rpoly)

    rpoly = rpoly * raw_reading
    temp + (1.5243e-10 * rpoly)
  end
end
