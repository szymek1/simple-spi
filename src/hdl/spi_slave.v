//////////////////////////////////////////////////////////////////////////////////
// Company: ISAE
// Engineer: Szymon Bogus
//
// Create Date: 28/07/2025
// Design Name:
// Module Name: spi_slave
// Project Name: simple-spi
// Target Devices: Zybo Z7-20
// Tool Versions:
// Description: SPI Slave module. This module decodes incomming message to either:
//              specify which LED to light up with a certain % of brightness or
//              to send back information about brightness level of the LED.
//              Module configured for SPI Mode 0.
//              It assumes an internal 125MHz clock and an external provided via
//              sclk input 26MHz one.
//
// Dependencies: params.vh
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments: synthesizeable
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
`include "../include/params.vh"


module spi_slave (
    input                               sysclk,
    input  wire                         sclk,
    input  wire                         cs,
    input  wire                         mosi,
    output wire                         miso,
    output wire [`LED_ADDR_WIDTH-1:0]   o_led_addr,
    output wire [`BRIGHTNESS_WIDTH-1:0] o_led_br_lvl,

);



endmodule