# Max31865

## Overview

Driver for the Max31865 thermocouple amplifier for use on a Raspberry Pi.  Tested with the Raspberry Pi Zero W V 1.2.  Should work similarly with other Raspberry PI devices.

For more detail on the Max31865 see the [datasheet](https://datasheets.maximintegrated.com/en/ds/MAX31865.pdf)

## Installation

Add to your deps

```elixir
defp deps do
    [
      ...
      {:max31865, "~> 0.1.0", hex: :max31865},
      ...
    ]
  end

```

## Usage

Start the server, passing in any required config.  The will allow for one-shot conversions using Spidev0.0 on a raspberry pi with a PT100 connected with either 2 or 4 wires.  For more information on configuration options, please see the [Server module](`Max31865.Server`).

```elixir
  def application do
    [
      {Max3186.Server, [rtd_wires: 3, spi_device_cs_pin: 1]}
      extra_applications: [:logger]
    ]
  end
```

Then you can get the temperature of the probe.  A conversion takes ~75ms to complete in one-shot mode.  The values returned are in degrees celcius.

```elixir
iex(1)> Max31865.get_temp()
22.79218286783738
```


