`ifndef PARAMS_V
`define PARAMS_V

// PWM (LED control)
`define BRIGHTNESS_WIDTH   7  // brightness level can vary: 0%-100%; 7-bit number required to store the input value
`define LED_MIN_BRIGHTNESS 0  // minimal level of brightness in %- min. duty cycle
`define LED_MAX_BRIGHTNESS 90 // maximal level of brightness in %- max. duty cycle

// Simulation
`define CLK_NS             8 // 125MHz => 8ns


`endif // PARAMS_V
