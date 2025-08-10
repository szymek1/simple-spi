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
    input                                 sysclk,
    input  wire                           sclk,
    input  wire                           cs,
    input  wire                           mosi,
    input  wire                           slv_tx_enb,  // acitve high to indicate that slave can 
                                                       // send the data back
    input  wire [`MASTER_FRAME_WIDTH-1:0] i_slv_frame, // input data frame- created outside
                                                       // transmitting LED data back
    output reg                            miso,
    output reg  [`CMD_BITS-1:0]           o_cmd,
    output reg  [`ADDR_BITS-1:0]          o_addr,
    output reg  [`PAYLOAD_BITS-1:0]       o_payload,
    output reg  [`MASTER_FRAME_WIDTH-1:0] o_shift_reg_debug,
    output reg                            o_serial_debug,
    output reg  [3:0]                     o_bit_rx_cnt_debug,
    output reg  [3:0]                     o_debug_stage
);

    // SPI Slave FSM
    localparam                    IDLE       = 3'b000; // moves to WAIT on cs set low
    localparam                    WAIT       = 3'b011; // waits for first sclk rising edge
    localparam                    COMMAND    = 3'b001;
    localparam                    ADDRESS    = 3'b010;
    localparam                    READ       = 3'b100;
    // localparam                    WRITE      = 3'b110;
    localparam                    DONE       = 3'b111;

    // Slave receiver
    reg                           rx_dv        = 1'b0; // high active when entire data frame is received
    reg [2:0]                     curr_state;
    reg [3:0]                     bit_rx_cnt   = 0;    // counts received bits to later on set high rx_dv
    reg [`MASTER_FRAME_WIDTH-1:0] shift_reg_rx = 0;    // received bits are saved in the shift register
    reg [1:0]                     slv_clk_cnt  = 2'b0; // counter of slvae-clock cycles until the middle of
                                                       // the master-clock is acheived                

    reg [1:0]                     wait_cnt     = 2'b0;

    // Slave transmitter
    reg [4:0]                     bit_tx_cnt   = 0;
    reg [`MASTER_FRAME_WIDTH-1:0] shift_reg_tx = 0;

    // sclk rising/falling edge detectors
    reg sclk_prev;
    reg sclk_sync;

    always @(posedge sysclk) begin
        sclk_prev <= sclk_sync;
        sclk_sync <= sclk;                      // synchronize SCLK to 125 MHz domain
    end

    wire sclk_rising  = sclk_sync & ~sclk_prev; // detect sclk rising edge
    wire sclk_falling = ~sclk_sync & sclk_prev; // detect sclk falling edge

    // Read process: triggered by cs active-low and sclk
    always @(posedge sysclk) begin
        if (cs == `CS_ASSERT) begin
            o_debug_stage  <= curr_state;
            o_bit_rx_cnt_debug <= bit_rx_cnt;
            case (curr_state)
                IDLE   : begin
                    rx_dv        <= 1'b0;
                    bit_rx_cnt   <= 0;
                    shift_reg_rx <= 0;
                    slv_clk_cnt  <= 2'b0;
                    wait_cnt     <= 2'b0;
                    curr_state   <= WAIT; // added to synchronize with mosi
                    o_shift_reg_debug <= shift_reg_rx;
                    o_serial_debug    <= mosi;
                end
                
                WAIT   : begin
                    rx_dv <= 1'b0;
                    bit_rx_cnt   <= 0;
                    shift_reg_rx <= 0;
                    slv_clk_cnt  <= 2'b0;
                    o_shift_reg_debug <= shift_reg_rx;
                    o_serial_debug    <= mosi;
                    if (sclk_rising) begin // wait for first sclk rising edge after CS low
                        curr_state <= COMMAND;
                    end
                end
                
                COMMAND: begin
                    rx_dv           <= 1'b0;
                    if (sclk_rising && bit_rx_cnt < `CMD_BITS) begin
                        slv_clk_cnt <= slv_clk_cnt + 1;
                    end else if (sclk_sync && slv_clk_cnt < 2'b11 && bit_rx_cnt < `CMD_BITS) begin
                        slv_clk_cnt <= slv_clk_cnt + 1;
                    end else if (sclk_sync && slv_clk_cnt == 2'b11 && bit_rx_cnt < `CMD_BITS) begin
                        shift_reg_rx <= {shift_reg_rx[`MASTER_FRAME_WIDTH-2:0], mosi};
                        bit_rx_cnt <= bit_rx_cnt + 1;
                        slv_clk_cnt <= 0;
                        o_shift_reg_debug <= shift_reg_rx;
                        o_serial_debug    <= mosi;
                    end else if (bit_rx_cnt == `CMD_BITS) begin
                        bit_rx_cnt <= 0;
                        curr_state <= ADDRESS;
                    end
                end
                ADDRESS: begin
                    rx_dv           <= 1'b0;
                    if (sclk_rising && bit_rx_cnt < `ADDR_BITS) begin
                        slv_clk_cnt <= slv_clk_cnt + 1;
                    end else if (sclk_sync && slv_clk_cnt < 2'b11 && bit_rx_cnt < `ADDR_BITS) begin
                        slv_clk_cnt <= slv_clk_cnt + 1;
                    end else if (sclk_sync && slv_clk_cnt == 2'b11 && bit_rx_cnt < `ADDR_BITS) begin
                        shift_reg_rx <= {shift_reg_rx[`MASTER_FRAME_WIDTH-2:0], mosi};
                        bit_rx_cnt <= bit_rx_cnt + 1;
                        slv_clk_cnt <= 0;
                        o_shift_reg_debug <= shift_reg_rx;
                        o_serial_debug    <= mosi;
                    end else if (bit_rx_cnt == `ADDR_BITS) begin
                        bit_rx_cnt <= 0;
                        curr_state <= READ;
                    end
                end
                READ  : begin
                    rx_dv           <= 1'b0;
                    if (sclk_rising && bit_rx_cnt < `PAYLOAD_BITS) begin
                        slv_clk_cnt <= slv_clk_cnt + 1;
                    end else if (sclk_sync && slv_clk_cnt < 2'b11 && bit_rx_cnt < `PAYLOAD_BITS) begin
                        slv_clk_cnt <= slv_clk_cnt + 1;
                    end else if (sclk_sync && slv_clk_cnt == 2'b11 && bit_rx_cnt < `PAYLOAD_BITS) begin
                        shift_reg_rx <= {shift_reg_rx[`MASTER_FRAME_WIDTH-2:0], mosi};
                        bit_rx_cnt <= bit_rx_cnt + 1;
                        slv_clk_cnt <= 0;
                        o_shift_reg_debug <= shift_reg_rx;
                        o_serial_debug    <= mosi;
                    end else if (bit_rx_cnt == `PAYLOAD_BITS) begin
                        // shift_reg_rx <= shift_reg_rx << 1'b1;
                        bit_rx_cnt <= 0;
                        curr_state <= DONE;
                    end
                end
                DONE   : begin
                    rx_dv      <= 1'b1; // single clock cycle pulse
                    o_cmd      <= shift_reg_rx[23:16];
                    o_addr     <= shift_reg_rx[15:8];
                    o_payload  <= shift_reg_rx[7:0];
                    curr_state <= IDLE;
                    o_shift_reg_debug <= shift_reg_rx;
                    o_serial_debug    <= mosi;

                end
                default: curr_state <= IDLE;
            endcase
        end else begin
            rx_dv        <= 1'b0;
            bit_rx_cnt   <= 0;
            shift_reg_rx <= 0;
            slv_clk_cnt  <= 2'b0;
            o_cmd        <= `CMD_NOP;
            o_addr       <= `ADDR_NONE;
            o_payload    <= `PAYLOAD_NONE;
            curr_state   <= IDLE;
            o_shift_reg_debug <= shift_reg_rx;
            o_serial_debug    <= mosi;
        end

    end

    // Write process: triggered on the falling edge of sclk
    always @(posedge sysclk) begin
        shift_reg_tx <= (slv_tx_enb == 1'b1) ? i_slv_frame : 0;
    end

    always @(posedge sysclk) begin
        if (sclk_falling && slv_tx_enb == 1'b1 && cs == `CS_ASSERT && bit_tx_cnt < `MASTER_FRAME_WIDTH) begin
            miso         <= shift_reg_tx[`MASTER_FRAME_WIDTH - 1];
            shift_reg_tx <= {shift_reg_tx[`MASTER_FRAME_WIDTH-2:0], 1'b0};
            bit_tx_cnt   <= bit_tx_cnt + 1'b1;
        end else if (cs == `CS_DEASSERT || bit_tx_cnt == `MASTER_FRAME_WIDTH) begin
            miso         <= 1'b0;
            shift_reg_tx <= 0;
        end
    end


endmodule