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
