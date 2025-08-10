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
    wire [`MASTER_FRAME_WIDTH-1:0]  o_shift_reg_debug;
    wire                            o_serial_debug;
    wire [3:0]                      o_debug_stage;
    wire [3:0]                      o_bit_rx_cnt_debug;

    // Utils: used to instantiate master i_frame
    reg  [`CMD_BITS-1:0]            mock_master_cmd_bits;
    reg  [`ADDR_BITS-1:0]           mock_master_addr_bits;
    reg  [`PAYLOAD_BITS-1:0]        mock_master_payload_bits;
    // used for slave i_slv_frame
    reg  [`CMD_BITS-1:0]            mock_slave_cmd_bits;
    reg  [`ADDR_BITS-1:0]           mock_slave_addr_bits;
    reg  [`PAYLOAD_BITS-1:0]        mock_slave_payload_bits;

    spi_master_mock spi_master_uut (
        .sysclk(clk),
        .tx_enb(tx_enb),
        .i_frame(i_frame),
        .miso(miso),
        .cs(cs),
        .sclk(sclk),
        .mosi(mosi),
        .o_frame(o_frame)
    );

    spi_slave spi_slave_uut (
        .sysclk(clk),
        .sclk(sclk),
        .cs(cs),
        .mosi(mosi),
        .slv_tx_enb(slv_tx_enb),
        .i_slv_frame(i_slv_frame),
        .miso(miso),
        .o_cmd(o_cmd),
        .o_addr(o_addr),
        .o_payload(o_payload),
        .o_shift_reg_debug(o_shift_reg_debug),
        .o_serial_debug(o_serial_debug),
        .o_bit_rx_cnt_debug(o_bit_rx_cnt_debug),
        .o_debug_stage(o_debug_stage)
    );

    task debug_display;
        $display("DEBUG-- T: %t stage: %b mosi: %b shift reg: %b", $time, o_debug_stage, o_serial_debug, o_shift_reg_debug);
    endtask

    initial begin
        clk = 0;
        forever #(`SLAVE_CLK_NS/2) clk = ~clk;
    end

    integer i;
    initial begin
        $dumpfile("spi_slave_tb_waveforms.vcd");
        /*
        $dumpvars(0, spi_slave_tb.clk,
                     spi_slave_tb.sclk,
                     spi_slave_tb.cs,
                     spi_slave_tb.miso,
                     spi_slave_tb.mosi,
                     spi_slave_tb.o_cmd,
                     spi_slave_tb.o_addr,
                     spi_slave_tb.o_payload,
                     spi_slave_tb.o_serial_debug,
                     spi_slave_tb.o_debug_stage);
        */
        $dumpvars(0, spi_slave_tb.clk,
                     spi_slave_tb.sclk,
                     spi_slave_tb.cs,
                     spi_slave_tb.mosi,
                     spi_slave_tb.o_shift_reg_debug,
                     spi_slave_tb.o_serial_debug,
                     spi_slave_tb.o_bit_rx_cnt_debug,
                     spi_slave_tb.o_debug_stage);
        
        // Initial conditions
        tx_enb     = 1'b0;
        slv_tx_enb = 1'b0;
        #(3 * `SLAVE_CLK_NS);

        // Test 1: master transmission only (set LED 2 to 10% brightness)
        mock_master_cmd_bits     = 8'b10000000;
        mock_master_addr_bits    = 8'b10100000;
        mock_master_payload_bits = 8'b11010001;
        i_frame                  = {mock_master_cmd_bits, 
                                    mock_master_addr_bits, 
                                    mock_master_payload_bits};
        tx_enb                   = 1'b1;

        $display("Master sending...");
        /*
        At the end the final outputs are the NOPs for respective
        elements: cmd, addr, data. 
        These loops also seem to be rushing. A different method should govern
        how these proceed.
        */

        // Wait for transaction completion
        #(`SLAVE_CLK_NS);
        @(posedge cs); // CS deasserts in DONE
        #(`SLAVE_CLK_NS);
        if (o_cmd == mock_master_cmd_bits) begin
            $display("Test 1.1: PASS- command bits received correctly");
        end else begin
            $display("Test 1.1: FAIL- got: %b, expected: %b cmd", o_cmd, mock_master_cmd_bits);
        end
        if (o_addr == mock_master_addr_bits) begin
            $display("Test 1.2: PASS- address bits received correctly");
        end else begin
            $display("Test 1.2: FAIL- got: %b, expected: %b addr", o_addr, mock_master_addr_bits);
        end
        if (o_payload == mock_master_payload_bits) begin
            $display("Test 1.3: PASS- payload bits received correctly");
        end else begin
            $display("Test 1.1: FAIL- got: %b, expected: %b data", o_payload, mock_master_payload_bits);
        end

        #(3 * `SLAVE_CLK_NS);
        $finish;

    end


endmodule