//////////////////////////////////////////////////////////////////////////////////
// Company: ISAE
// Engineer: Szymon Bogus
//
// Create Date: 25/08/2025
// File Name: spi_utils.h
// Project Name: simple-spi
// Target Devices: ESP32-S3
// Tool Versions:
// Description: SPI utilities functions and structures declarations.
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
#ifndef SPI_UTILS_H
#define SPI_UTILS_H

#include <driver/spi_master.h>
#include <esp_err.h>

#include "configuration.h"


extern spi_device_handle_t spi_handle;

/**
 * @brief Initialize the SPI Master bus and device on ESP32-S3.
 * 
 * Configures the SPI bus with the pins and frequency from configuration.h,
 * adds the device with CS pin and mode 0.
 * 
 * @return ESP_OK on success, or error code.
 */
esp_err_t spi_init(void);

/**
 * @brief Send a CMD_LED_SET command to set LED brightness on the FPGA slave.
 * 
 * Prepares and transmits a 24-bit frame: CMD_LED_SET (8 bits) + addr (8 bits) + (brightness << 1) (8 bits).
 * Ignores received data (full-duplex but no meaningful RX for set).
 * 
 * @param addr LED address (0 to NUM_LEDS-1).
 * @param brightness 7-bit brightness value (0-127).
 * @return ESP_OK on success, or error code.
 */
esp_err_t spi_set_led(uint8_t addr, uint8_t brightness);

/**
 * @brief Send a CMD_LED_READ command to read LED brightness from the FPGA slave.
 * 
 * Transmits a 24-bit frame: CMD_LED_READ (8 bits) + addr (8 bits) + dummy 0x00 (8 bits).
 * Receives the brightness in the last 8 bits (full-duplex), extracts [7:1] >> 1.
 * 
 * @param addr LED address (0 to NUM_LEDS-1).
 * @param brightness Pointer to store the 7-bit brightness value.
 * @return ESP_OK on success, or error code.
 */
esp_err_t spi_read_led(uint8_t addr, uint8_t *brightness);

#endif // SPI_UTILS_H