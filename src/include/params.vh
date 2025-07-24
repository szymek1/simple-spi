`ifndef PARAMS_V
`define PARAMS_V

// PWM (LED control)
`define BRIGHTNESS_WIDTH   7    // brightness level can vary: 0%-100%; 7-bit number required to store the input value
`define LED_MIN_BRIGHTNESS 0    // minimal level of brightness in %- min. duty cycle
`define LED_MAX_BRIGHTNESS 90   // maximal level of brightness in %- max. duty cycle

// Simulation
`define SLAVE_CLK_NS       8    // 125MHz => 8ns | Frequency related to Xilinx Zynq 7020
`define MASTER_CLK_NS      38.5 // 26MHz =? 38.5ns | Frequency of ESP32 SPI Master     


`endif // PARAMS_V
