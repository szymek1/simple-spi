//////////////////////////////////////////////////////////////////////////////////
// Company: ISAE
// Engineer: Szymon Bogus
//
// Create Date: 24/07/2025
// Design Name:
// Module Name: spi_master_mock_tb
// Project Name: simple-spi
// Target Devices: Zybo Z7-20
// Tool Versions:
// Description: Testbench for mock SPI Master module. 
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


module spi_master_mock_tb (

);

    // Inputs
    reg                            clk;
    reg                            tx_enb;
    reg  [`MASTER_FRAME_WIDTH-1:0] i_frame;
    reg                            miso;

    // Utils
    reg [`CMD_BITS-1:0]            cmd_bits;
    reg [`ADDR_BITS-1:0]           addr_bits;
    reg [`PAYLOAD_BITS-1:0]        payload_bits;

    // Outputs
    wire                           cs;
    wire                           sclk;
    wire                           mosi;
    wire [`BRIGHTNESS_WIDTH-1:0]   o_frame;

    spi_master_mock uut (
        .sysclk(clk),
        .tx_enb(tx_enb),
        .i_frame(i_frame),
        .miso(miso),
        .cs(cs),
        .sclk(sclk),
        .mosi(mosi),
        .o_frame(o_frame)
    );

    initial begin
        clk = 0;
        forever #(`SLAVE_CLK_NS/2) clk = ~clk;
    end

    integer i;
    initial begin
        $dumpfile("spi_master_mock_tb_waveforms.vcd"); // Add waveform dumping
        $dumpvars(0, spi_master_mock_tb.clk,
                     spi_master_mock_tb.sclk,
                     spi_master_mock_tb.cs,
                     spi_master_mock_tb.tx_enb,
                     spi_master_mock_tb.mosi,
                     spi_master_mock_tb.i_frame,
                     spi_master_mock_tb.miso,
                     spi_master_mock_tb.o_frame);

        // Initial conditions
        tx_enb = 1'b0;
        #(3 * `SLAVE_CLK_NS);

        // Test 1: cs deasserted
        if (cs == `CS_DEASSERT) begin
            $display("Test 1: PASS- cs deasserted");
        end else begin
            $display("Test 1: FAIL- got: %b, expected: %b", cs, `CS_DEASSERT);
        end

        // Test 2: only transmission (MSB convention)
        cmd_bits     = 8'b10000000;
        addr_bits    = 8'b10100000;
        payload_bits = 8'b11010000;
        i_frame      = {cmd_bits, addr_bits, payload_bits};
        tx_enb       = 1'b1;

        $display("Command bits testting...");
        #(`SLAVE_CLK_NS);
        for (i = 0; i < `CMD_BITS; i = i + 1) begin
            #(`MASTER_CLK_NS);
            if (cs == `CS_ASSERT) begin
                $display("Test 2.1.%d cs asserted PASS", i);
            end else begin
                $display("Test 2.1.%d FAIL- got: %b, expected: %b", i, cs, `CS_DEASSERT);
            end
            if (mosi == cmd_bits[(`CMD_BITS-1) - i]) begin
                $display("Test 2.1.%d mosi correct: %b", i, mosi);
            end else begin
                $display("Test 2.1.%d mosi incorrect: %b, expected: %b", i, mosi, cmd_bits[(`CMD_BITS-1) - i]);
            end
        end

        $display("Address bits testting...");
        #(`SLAVE_CLK_NS);
        for (i = 0; i < `ADDR_BITS; i = i + 1) begin
            #(`MASTER_CLK_NS);
            if (cs == `CS_ASSERT) begin
                $display("Test 2.2.%d cs asserted PASS", i);
            end else begin
                $display("Test 2.2.%d FAIL- got: %b, expected: %b", i, cs, `CS_DEASSERT);
            end
            if (mosi == addr_bits[(`ADDR_BITS-1) - i]) begin
                $display("Test 2.2.%d mosi correct: %b", i, mosi);
            end else begin
                $display("Test 2.2.%d mosi incorrect: %b, expected: %b", i, mosi, addr_bits[(`ADDR_BITS-1) - i]);
            end
        end

        $display("Payload bits testting...");
        #(`SLAVE_CLK_NS);
        for (i = 0; i < `PAYLOAD_BITS; i = i + 1) begin
            #(`MASTER_CLK_NS);
            if (cs == `CS_ASSERT) begin
                $display("Test 2.3.%d cs asserted PASS", i);
            end else begin
                $display("Test 2.3.%d FAIL- got: %b, expected: %b", i, cs, `CS_DEASSERT);
            end
            if (mosi == payload_bits[(`PAYLOAD_BITS-1) - i]) begin
                $display("Test 2.3.%d mosi correct: %b", i, mosi);
            end else begin
                $display("Test 2.3.%d mosi incorrect: %b, expected: %b", i, mosi, payload_bits[(`PAYLOAD_BITS-1) - i]);
            end
        end

        #(3 * `SLAVE_CLK_NS);
        $finish;

    end

endmodule