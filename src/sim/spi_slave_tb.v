//////////////////////////////////////////////////////////////////////////////////
// Company: ISAE
// Engineer: Szymon Bogus
//
// Create Date: 08/08/2025
// Design Name:
// Module Name: spi_slave_tb
// Project Name: simple-spi
// Target Devices: Zybo Z7-20
// Tool Versions:
// Description: Testbench for mock SPI Slave module. 
//              It assumes FPGA internal clock of 125MHz and 26Mhz SPI Master clock.
//
// Dependencies: params.vh
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
`include "../include/params.vh"


module spi_slave_tb (

);

    // Inputs: master&slave
    reg                             clk;
    
    // Inputs: master
    reg                             tx_enb;
    reg  [`MASTER_FRAME_WIDTH-1:0]  i_frame;
    wire                            miso; // output for slave

    // Outputs: master -> inputs: slave
    wire                            cs;
    wire                            sclk;
    wire                            mosi;
    wire                            o_frame;

    // Inputs: slave
    reg                             slv_tx_enb;
    reg  [`MASTER_FRAME_WIDTH-1:0]  i_slv_frame;

    // Outputs: slave (everything except of miso)
    wire [`CMD_BITS-1:0]            o_cmd;
    wire [`ADDR_BITS-1:0]           o_addr;
    wire [`PAYLOAD_BITS-1:0]        o_payload;

    // Utils: used to instantiate master i_frame
    reg  [`CMD_BITS-1:0]            mock_master_cmd_bits;
    reg  [`ADDR_BITS-1:0]           mock_master_addr_bits;
    reg  [`PAYLOAD_BITS-1:0]        mock_master_payload_bits;
    // used for slave i_slv_frame
    reg  [`CMD_BITS-1:0]            mock_slave_cmd_bits;
    reg  [`ADDR_BITS-1:0]           mock_slave_addr_bits;
    reg  [`PAYLOAD_BITS-1:0]        mock_slave_payload_bits;




endmodule