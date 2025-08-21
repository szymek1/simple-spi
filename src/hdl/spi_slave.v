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
    // Inputs
    // Internal FPGA clock
    input                                  sysclk,
    // Coming from SPI Master
    input  wire                            sclk,
    input  wire                            cs,
    input  wire                            mosi,
    // Coming from spi_top
    input  wire [7:0]                      i_tx_payload,  // last 8 bits of transmission in case
                                                          // of CMD_LED_READ
    // Outputs
    output reg                             miso,
    output wire  [`CMD_BITS-1:0]           o_cmd,
    output wire  [`ADDR_BITS-1:0]          o_addr,
    output wire  [`PAYLOAD_BITS-1:0]       o_payload,
    // Flags indicating completed operations
    output wire                            rx_dv,         // active high when transaction for CMD_LED_SET is completed
                                                          // otherwise irrelevant
    output wire                            rd_bypass,     // active high when CMD_LED_READ is detected
    output reg                             rx_addr_dv,    // active high for CMD_LED_READ when receiving
                                                          // read address is done
    // Debug outputs
    output reg   [`MASTER_FRAME_WIDTH-1:0] o_shift_reg_debug,
    output reg                             o_serial_debug,
    output reg   [4:0]                     o_bit_rx_cnt_debug,
    output reg   [2:0]                     o_debug_stage
);

    // SPI Slave FSM
    localparam IDLE    = 3'b000;
    localparam COMMAND = 3'b001;
    localparam ADDRESS = 3'b010;
    localparam WRITE   = 3'b011;
    localparam DONE    = 3'b111;

    // Slave receiver
    reg [2:0]                     curr_state      = IDLE;
    reg [4:0]                     bit_rx_cnt      = 0;
    reg [`MASTER_FRAME_WIDTH-1:0] shift_reg_rx    = 0;
    reg                           first_edge_seen = 0;  // flag to track first SCLK edge

    // Slave transmitter
    reg [4:0]                     bit_tx_cnt      = 0;
    reg [7:0]                     tx_payload_reg  = 0;  // loaded payload for read responses

    // rx_cmd and rx_addr are relevant when CMD_LED_READ is detected (rx_cmd)
    // in order to notify about the read command and read address (rx_addr)
    reg [`CMD_BITS-1:0]           rx_cmd     = `CMD_NOP;
    reg [`ADDR_BITS-1:0]          rx_addr    = `ADDR_NONE;

    // Clock edge detection with proper synchronization
    reg [2:0]                     sclk_sync = 3'b000;
    
    always @(posedge sysclk) begin
        sclk_sync <= {sclk_sync[1:0], sclk};
    end
    
    wire                           sclk_rising  = (sclk_sync[2:1] == 2'b01);
    wire                           sclk_falling = (sclk_sync[2:1] == 2'b10);

    // CS edge detection
    reg [2:0]                      cs_sync = 3'b111;
    always @(posedge sysclk) begin
        cs_sync <= {cs_sync[1:0], cs};
    end
    
    wire                           cs_falling = (cs_sync[2:1] == 2'b10);

    // Main FSM for receiving data
    always @(posedge sysclk) begin
        if (cs_sync[1] == `CS_DEASSERT) begin
            curr_state      <= IDLE;
            bit_rx_cnt      <= 0;
            first_edge_seen <= 0;
        end
        else begin
            /*
            // debug outputs
            o_debug_stage      <= curr_state;
            o_bit_rx_cnt_debug <= bit_rx_cnt[3:0];
            o_shift_reg_debug  <= shift_reg_rx;
            o_serial_debug     <= mosi;
            */
            o_debug_stage      <= curr_state;
            case (curr_state)
                IDLE   : begin
                    if (cs_falling) begin
                        curr_state      <= COMMAND;
                        bit_rx_cnt      <= 0;
                        first_edge_seen <= 0;
                        shift_reg_rx    <= 0; // reset shift register when starting new transaction
                        rx_cmd          <= `CMD_NOP;
                        rx_addr         <= `ADDR_NONE;
                        rx_addr_dv      <= 1'b0;
                    end
                end
                
                COMMAND: begin
                    if (sclk_rising) begin
                        if (!first_edge_seen) begin
                            // skip the very first SCLK rising edge - master hasn't set up data yet
                            first_edge_seen <= 1;
                        end else begin
                            shift_reg_rx    <= {shift_reg_rx[`MASTER_FRAME_WIDTH-2:0], mosi};
                            bit_rx_cnt      <= bit_rx_cnt + 1;
                        end
                    end

                    if (bit_rx_cnt == `CMD_BITS) begin
                        rx_cmd     <= shift_reg_rx[7:0]; // command here occupies those bits
                        curr_state <= ADDRESS;
                        bit_rx_cnt <= 0;
                    end
                end
                
                ADDRESS: begin
                    if (sclk_rising) begin
                        shift_reg_rx   <= {shift_reg_rx[`MASTER_FRAME_WIDTH-2:0], mosi};
                        bit_rx_cnt     <= bit_rx_cnt + 1;
                        if (bit_rx_cnt == `ADDR_BITS - 1) begin
                            rx_addr    <= {shift_reg_rx[6:0], mosi};  // full address after last shift
                            rx_addr_dv <= 1'b1;                       // notify spi_top that a valid read address is ready
                        end
                    end

                    if (bit_rx_cnt == `ADDR_BITS) begin
                        curr_state <= WRITE;
                        bit_rx_cnt <= 0;
                        if (rx_cmd == `CMD_LED_READ) begin
                            tx_payload_reg <= i_tx_payload;  // load payload for transmission in write phase
                                                             // provided by spi_top
                        end
                    end
                end
                
                WRITE  : begin
                    if (sclk_rising) begin
                        shift_reg_rx <= {shift_reg_rx[`MASTER_FRAME_WIDTH-2:0], mosi};
                        bit_rx_cnt   <= bit_rx_cnt + 1;
                    end
                     
                    if (bit_rx_cnt == `PAYLOAD_BITS) begin
                        curr_state   <= DONE;
                        bit_rx_cnt   <= 0;
                    end
                end
                
                DONE   : begin
                    curr_state <= IDLE;
                end
                
                default: begin
                    curr_state <= IDLE;
                end
            endcase
        end
    end

    // Output assignments - data is valid when CS is deasserted (rx_dv high) and CMD_LED_SET
    // otherwise CMD_LED_READ is issued so cmd and addr are bypassed earlier thus
    // letting spi_top prepare a payload to send
    assign rx_dv     = (cs_sync[1] == `CS_DEASSERT) ? 1'b1                : 1'b0;
    assign rd_bypass = (rx_cmd == `CMD_LED_READ)    ? 1'b1                : 1'b0;
    
    assign o_cmd     = (rx_dv == 1'b1)              ? shift_reg_rx[23:16] : 
                       (rd_bypass == 1'b1)          ? rx_cmd              : `CMD_NOP;

    assign o_addr    = (rx_dv == 1'b1)              ? shift_reg_rx[15:8]  :
                       (rd_bypass == 1'b1)          ? rx_addr             : `ADDR_NONE;

    assign o_payload = (rx_dv == 1'b1)              ? shift_reg_rx[7:0]   : `PAYLOAD_NONE;

    // Transmit logic - setup data on falling edge of SCLK (SPI Mode 0)
    always @(posedge sysclk) begin
        if (cs_sync[1] == `CS_DEASSERT || cs_falling) begin
            bit_tx_cnt     <= 0;
            miso           <= 0; 
            tx_payload_reg <= 0;  
        end else begin
            if (sclk_falling) begin
                if (bit_tx_cnt < `MASTER_FRAME_WIDTH) begin
                    if (bit_tx_cnt < `CMD_BITS + `ADDR_BITS) begin  // first 16 bits are always 0!!!
                        miso   <= 0;
                    end else begin  // last 8 bits: payload (0 for CMD_LED_SET, LED value for CMD_LED_READ)
                        miso   <= tx_payload_reg[`PAYLOAD_BITS - 1 - (bit_tx_cnt - (`CMD_BITS + `ADDR_BITS))];
                    end
                    bit_tx_cnt <= bit_tx_cnt + 1;
                end
            end
        end
    end

endmodule