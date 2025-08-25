//////////////////////////////////////////////////////////////////////////////////
// Company: ISAE
// Engineer: Szymon Bogus
//
// Create Date: 25/08/2025
// File Name: spi_utils.c
// Project Name: simple-spi
// Target Devices: ESP32-S3
// Tool Versions:
// Description: SPI utilities functions and structures definitions.
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
#include <esp_log.h>

#include "../include/spi_utils.h"


static const char *TAG = "SPI_UTILS";

spi_device_handle_t spi_handle;

esp_err_t spi_init(void) {
    esp_err_t ret;

    // Bus configuration
    spi_bus_config_t bus_cfg = {
        .mosi_io_num = GPIO_MOSI,
        .miso_io_num = GPIO_MISO,
        .sclk_io_num = GPIO_SCLK,
        .quadwp_io_num = -1,  // not used
        .quadhd_io_num = -1,  // not used
        .max_transfer_sz = 0, 
    };

    // Initialize the SPI bus (DMA disabled for small transfers)
    ret = spi_bus_initialize(SPI_HOST, &bus_cfg, SPI_DMA_DISABLED);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "SPI bus init failed: %s", esp_err_to_name(ret));
        return ret;
    }

    // Device configuration
    spi_device_interface_config_t dev_cfg = {
        .clock_speed_hz = SCLK_FRQ_HZ,
        .mode = SPI_MODE,
        .spics_io_num = GPIO_CS,
        .queue_size = 1,  // single transaction queue
        .flags = 0,       // full-duplex by default
    };

    // Add device to bus
    ret = spi_bus_add_device(SPI_HOST, &dev_cfg, &spi_handle);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "SPI device add failed: %s", esp_err_to_name(ret));
        return ret;
    }

    ESP_LOGI(TAG, "SPI Master initialized successfully");
    return ESP_OK;
}

esp_err_t spi_set_led(uint8_t addr, uint8_t brightness) {
    if (addr >= NUM_LEDS) {
        ESP_LOGE(TAG, "Invalid LED address: %d", addr);
        return ESP_ERR_INVALID_ARG;
    }

    // Prepare 24-bit TX data: cmd | addr | (brightness << 1)
    uint8_t tx_data[3] = {CMD_LED_SET, addr, (brightness << BRIGHTNESS_SHIFT)};

    // Transaction struct
    spi_transaction_t trans = {
        .length = FRAME_BITS,  // in bits
        .tx_buffer = tx_data,
        .rx_buffer = NULL,     // ignore RX for set
    };

    esp_err_t ret = spi_device_polling_transmit(spi_handle, &trans);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "SPI set transaction failed: %s", esp_err_to_name(ret));
    } else {
        ESP_LOGI(TAG, "Set LED %d to brightness %d", addr, brightness);
    }

    return ret;
}

esp_err_t spi_read_led(uint8_t addr, uint8_t *brightness) {
    if (addr >= NUM_LEDS || brightness == NULL) {
        ESP_LOGE(TAG, "Invalid LED address or null pointer");
        return ESP_ERR_INVALID_ARG;
    }

    // Prepare TX: cmd | addr | dummy (0x00)
    uint8_t tx_data[3] = {CMD_LED_READ, addr, PAYLOAD_NONE};
    uint8_t rx_data[3] = {0};

    // Transaction (full-duplex)
    spi_transaction_t trans = {
        .length = FRAME_BITS,
        .tx_buffer = tx_data,
        .rx_buffer = rx_data,
    };

    esp_err_t ret = spi_device_polling_transmit(spi_handle, &trans);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "SPI read transaction failed: %s", esp_err_to_name(ret));
        return ret;
    }

    // Extract brightness from RX payload [7:1] >> 1
    *brightness = (rx_data[2] >> BRIGHTNESS_SHIFT);
    ESP_LOGI(TAG, "Read LED %d brightness: %d", addr, *brightness);

    return ESP_OK;
}
