//////////////////////////////////////////////////////////////////////////////////
// Company: ISAE
// Engineer: Szymon Bogus
//
// Create Date: 25/08/2025
// File Name: configuration.h
// Project Name: simple-spi
// Target Devices: ESP32-S3
// Tool Versions:
// Description: GPIO and SPI configuration information.
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
#ifndef CONFIGURATION_H
#define CONFIGURATION_H

// SPI
// ESP32 pinout
#define GPIO_MOSI    11
#define GPIO_MISO    13
#define GPIO_SCLK    12
#define GPIO_CS      10

// Master clock settings
#define SCLK_FRQ_HZ (26 * 1000 * 1000) // 26Mhz

// SPI Mode
#define SPI_MODE     0
#define SPI_HOST     SPI2_HOST

// Data frame settings (24 bits: 8 cmd + 8 addr + 8 payload)
#define FRAME_BITS   24

// commands
#define CMD_LED_SET  0x01
#define CMD_LED_READ 0x02
#define CMD_NOP      0x00

// address and payload defaults
#define ADDR_NONE    0x0D
#define PAYLOAD_NONE 0x00

// LEDs
#define NUM_LEDS     8

// Brightness is 7-bit (0-127), shifted left by 1 in payload (LSB ignored)
#define BRIGHTNESS_SHIFT 1

#endif // CONFIGURATION_H