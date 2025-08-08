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
//              Module configured for SPI Mode 0.
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
    input                                 sysclk,
    input  wire                           tx_enb,      // high active for data frame ready to send
    input  wire [`MASTER_FRAME_WIDTH-1:0] i_frame,     // input data frame- its creation is done outside of the module
    input  wire                           miso,        // read input from slave
    output reg                            cs,          // chip select (active low)
    output wire                           sclk,        // clock signal issued to slave
    output reg                            mosi,        // serial master output
    output wire [`BRIGHTNESS_WIDTH-1:0]   o_frame      // entire response
);

    // SPI Master FSM
    localparam                    IDLE       = 3'b000;   // on transition from IDLE to COMMAND cs is asserted
    localparam                    COMMAND    = 3'b001;
    localparam                    ADDRESS    = 3'b010;
    // localparam                    READ       = 3'b100;
    localparam                    WRITE      = 3'b110;
    localparam                    DONE       = 3'b111;   // deasserts cs

    // Master transmitter + sclk generation
    reg [2:0]                     curr_state;
    reg [4:0]                     bit_frame_cnt;       // indexing what is the current bit from data frame to send
    reg                           sclk_int     = 1'b0; // internal output master clock
    reg [2:0]                     sclk_cnt     = 0;    // count cycles of 125Mhz frequency clock before issuing sclk pulse
    reg [`MASTER_FRAME_WIDTH-1:0] shift_reg_tx;        // transmit shift register

    // Master receiver
    reg [2:0]                     bit_rx_cnt   = 0;
    reg [`MASTER_FRAME_WIDTH-1:0] shift_reg_rx = 0;    // receive shift register

    // 26MHz pulse generator
    /*
    always @(posedge sysclk) begin
        if (sclk_cnt == (`CLKS_PER_MASTER_SCLK - 1)) begin
            sclk_int   <= 1'b1;
            sclk_cnt   <= 0;
        end else begin
            sclk_int   <= 1'b0;
            sclk_cnt   <= sclk_cnt + 1'b1;
        end
    end
    */
    reg                           sclk_prev;
    always @(posedge sysclk) begin
        sclk_prev      <= sclk_int;
        if (sclk_cnt == (`CLKS_PER_MASTER_SCLK - 1)) begin
            sclk_int   <= ~sclk_int;
            sclk_cnt   <= 0;
        end else begin
            sclk_int   <= sclk_int;
            sclk_cnt   <= sclk_cnt + 1'b1;
        end
    end
    wire   sclk_falling = sclk_prev  & ~sclk_int;
    wire   sclk_rising  = ~sclk_prev & sclk_int;
    assign sclk         = sclk_int;

    // Write process: triggered on the falling edge sclk_int
    always @(posedge sysclk) begin 
        case (curr_state)
            IDLE   : begin
                cs               <= `CS_DEASSERT;
                bit_frame_cnt    <= 0;
                mosi             <= 1'b0;
                shift_reg_tx     <= 0;
                if (tx_enb == 1'b1) begin
                    shift_reg_tx <= i_frame;
                    cs           <= `CS_ASSERT;
                    curr_state   <= COMMAND;
                end
            end
            COMMAND: begin
                cs                <= `CS_ASSERT;
                if (sclk_falling && bit_frame_cnt <= (`CMD_BITS - 1)) begin // sclk_int
                    mosi          <= shift_reg_tx[`MASTER_FRAME_WIDTH - 1];
                    shift_reg_tx  <= {shift_reg_tx[`MASTER_FRAME_WIDTH-2:0], 1'b0};
                    bit_frame_cnt <= bit_frame_cnt + 1'b1;
                end else if (bit_frame_cnt == `CMD_BITS) begin
                    bit_frame_cnt <= 0;
                    curr_state    <= ADDRESS;
                end
            end
            ADDRESS: begin
                cs                <= `CS_ASSERT;
                if (sclk_falling && bit_frame_cnt <= (`ADDR_BITS - 1)) begin
                    mosi          <= shift_reg_tx[`MASTER_FRAME_WIDTH - 1];
                    shift_reg_tx  <= {shift_reg_tx[`MASTER_FRAME_WIDTH-2:0], 1'b0};
                    bit_frame_cnt <= bit_frame_cnt + 1'b1;
                end else if (bit_frame_cnt == `ADDR_BITS) begin
                    bit_frame_cnt <= 0;
                    curr_state    <= WRITE;
                end
            end
            WRITE  : begin
                cs                <= `CS_ASSERT;
                if (sclk_falling && bit_frame_cnt <= (`PAYLOAD_BITS - 1)) begin
                    mosi          <= shift_reg_tx[`MASTER_FRAME_WIDTH - 1];
                    shift_reg_tx  <= {shift_reg_tx[`MASTER_FRAME_WIDTH-2:0], 1'b0};
                    bit_frame_cnt <= bit_frame_cnt + 1'b1;
                end else if (bit_frame_cnt == `PAYLOAD_BITS) begin
                    bit_frame_cnt <= 0;
                    curr_state    <= DONE;
                end
            end
            DONE   : begin
                cs            <= `CS_DEASSERT;
                // mosi          <= 1'b0; // latching on the very last bit
                bit_frame_cnt <= 0;
                shift_reg_tx  <= 0;
                curr_state    <= IDLE;
            end
            default: curr_state <= IDLE;
        endcase
    end

    // Read process: triggered on the rising edge sclk_int
    always @(posedge sysclk) begin
        if (sclk_rising && curr_state != IDLE && curr_state != DONE) begin // sclk_cnt == (`CLKS_PER_MASTER_SCLK - 1) && s
            shift_reg_rx <= {shift_reg_rx[`MASTER_FRAME_WIDTH-2:0], miso};
            bit_rx_cnt   <= bit_rx_cnt + 1;
            if (bit_rx_cnt == `MASTER_FRAME_WIDTH - 1) begin
                bit_rx_cnt <= 0;
            end
        end
    end
    assign o_frame = shift_reg_rx[6:0];

endmodule