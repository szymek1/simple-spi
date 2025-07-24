//////////////////////////////////////////////////////////////////////////////////
// Company: ISAE
// Engineer: Szymon Bogus
//
// Create Date: 24/07/2025
// Design Name:
// Module Name: spi_master_mock
// Project Name: simple-spi
// Target Devices: Zybo Z7-20
// Tool Versions:
// Description: Mock-up ESP32 SPI Master designed to simulate the micrcontroller
//              SPI master behavior used to validate actually synthesizeable
//              FPGA SPI slave.
//
// Dependencies: params.vh
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments: not synthesizeable, only for simulation
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
`include "../include/params.vh"


module spi_master_mock (
    input                                 sclk,
    input  wire [`MASTER_FRAME_WIDTH-1:0] i_frame, // input data frame- its creation is done outside of the module
    input  wire [`BRIGHTNESS_WIDTH:0]     miso,    // read input from slave
    output wire                           cs,      // chip select (active low)
    output reg                            mclk,    // clock signal issued to slave
    output reg                            mosi,    // serial master output
);

    // SPI Master FSM
    localparam IDLE    3'b000; // on transition from IDLE to COMMAND cs is asserted
    localparam COMMAND 3'b001;
    localparam ADDRESS 3'b010;
    localparam READ    3'b100;
    localparam WRITE   3'b110;
    localparam DONE    3'b111; // deasserts cs

    reg [2:0]  curr_state;


endmodule