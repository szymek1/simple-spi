`ifndef PARAMS_V
`define PARAMS_V

// PWM (LED control)
`define BRIGHTNESS_WIDTH     7    // brightness level can vary: 0%-100%; 7-bit number required to store the input value
`define LED_MIN_BRIGHTNESS   0    // minimal level of brightness in %- min. duty cycle
`define LED_MAX_BRIGHTNESS   90   // maximal level of brightness in %- max. duty cycle
`define LED_ADDR_WIDTH       4    // 13 addressable LEDs with 4-bit long addresses

// SPI
// SPI data frame
`define MASTER_FRAME_WIDTH   24   // 24 bits wide master data frame
`define CLKS_PER_MASTER_SCLK 5    // FPGA has 125Mhz clock but ESP32 SPI Master has 26MHz, this parameter specifies how many 
                                  // 125Mhz frequency clock cycles to wait before issuing 25Mhz pulse

// Master data frame enconding
// CMD
`define CMD_LED_SET          8'h1
`define CMD_LED_READ         8'h2
`define CMD_NOP              8'h0
// ADDR
`define ADDR_NONE            8'hD
// PAYLOAD
`define PAYLOAD_NONE         8'h0


// SPI Master data frame is 24 bits wide and each section: command, address, payload
// is equally 8 bits wide, however, when the data for a section isn't encoded with 8 bits
// but with n-bits then first n-bits are important and the rest is garbage
`define CMD_BITS             8 // first 2 bits matter
`define ADDR_BITS            8 // first 4 bits matter
`define PAYLOAD_BITS         8 // first 7 bits matter | corresponds to payload of both master and slave

// CS
`define CS_ASSERT            1'b0
`define CS_DEASSERT          1'b1

// Simulation
`define SLAVE_CLK_NS         8    // 125MHz => 8ns | Frequency related to Xilinx Zynq 7020
`define MASTER_CLK_NS        38.5 // 26MHz =? 38.5ns | Frequency of ESP32 SPI Master     


`endif // PARAMS_V
