#include "../include/spi_utils.h"
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <esp_log.h>


static const char *TAG = "SPI_MASTER_ESP32";


void app_main(void) {
    esp_err_t ret = spi_init();
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "SPI init failed, halting");
        while (1) vTaskDelay(1000 / portTICK_PERIOD_MS);
    }

    // Test loop: Set and read LEDs
    while (1) {
        // Set LED 0 to 64 (mid brightness)
        spi_set_led(0, 64);

        // Read LED 0
        uint8_t brightness;
        spi_read_led(0, &brightness);
        ESP_LOGI(TAG, "LED 0 brightness: %d", brightness);

        // Set LED 7 to 127 (max brightness)
        spi_set_led(7, 127);

        // Read LED 7
        spi_read_led(7, &brightness);
        ESP_LOGI(TAG, "LED 7 brightness: %d", brightness);

        // Delay 1 second
        vTaskDelay(1000 / portTICK_PERIOD_MS);
    }
}
