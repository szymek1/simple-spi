# simple-spi
## Overview
This project implements SPI-based communication between a microcontroller and an FPGA. 

The microcontroller acts as an SPI master and sends commands to an FPGA which servers as a slave. The commands are:

- light up/down an LED
- get LED status

FPGA in return sends back responses describing its action.

## Hardware
This project makes use of:

- [ESP-32-S3 DevKitM1](https://docs.espressif.com/projects/esp-dev-kits/en/latest/esp32s3/esp32-s3-devkitm-1/index.html)
- [Xilinx Zybo Z7-20](https://digilent.com/shop/zybo-z7-zynq-7000-arm-fpga-soc-development-board/)
- set of LEDs
- OLED display
- gauge

## Build
In order to generate bitstream and netlist execute:
```
make build
```

Programming the device is done with:
```
make program_fpga
```

In order to customize this implementation please adjust project's section of Makefile:
```Makefile
# Project's details
project_name    := simple_spi
top_module          := spi_top
language            := verilog
device              := xc7z020clg400-1 # use device specific name
```

Don't forget to provide your own ```.xdc``` file to ```src/constraints/``` directory.

## Simulation
Running simulations is also possible. All testbenches have to be stored inside ```src/sim/```.

Tesbenches can be either run all or selected.
To run all of them:
```
make sim_all
```

To run selected:
```
make sim_sel TB="uart_top_tb uart_rx_tb ..."
```

Results will be stored inside ```simulation/waveforms``` directory that will be created during the first run of make.

## Closing
If you enjoy this project's structure and build system please check my other [project](https://github.com/szymek1/FPGA-TCL-Makefile-template).
