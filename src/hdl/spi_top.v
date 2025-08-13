//////////////////////////////////////////////////////////////////////////////////
// Company: ISAE
// Engineer: Szymon Bogus
//
// Create Date: 13/08/2025
// Design Name:
// Module Name: spi_slave
// Project Name: simple-spi
// Target Devices: Zybo Z7-20
// Tool Versions:
// Description: Top module, responsible for SPI slave. It's receiving and
//              interpreting commands. It uses PWM to control LEDs brightness level.
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


module spi_top (
    // Inputs
    // Internal FPGA clock
    input                                  sysclk,
    // Inputs provided through PMOD JA
    input  wire                            sclk,
    input  wire                            cs,
    input  wire                            mosi,
    // input  wire                            slv_tx_enb,  // issued interanlly
    // input  wire  [`MASTER_FRAME_WIDTH-1:0] i_slv_frame, // created internally
    // Outputs
    // PMOD JA output
    output reg                             miso,
    // PMOD JE outputs (LEDs)
    output wire                            led1;
    output wire                            led2;
    output wire                            led3;
    output wire                            led4;
    output wire                            led5;
    output wire                            led6;
    output wire                            led7;
    output wire                            led8;
);




endmodule