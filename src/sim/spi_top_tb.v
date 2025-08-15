//////////////////////////////////////////////////////////////////////////////////
// Company: ISAE
// Engineer: Szymon Bogus
//
// Create Date: 13/08/2025
// Design Name:
// Module Name: spi_top_tb
// Project Name: simple-spi
// Target Devices: Zybo Z7-20
// Tool Versions:
// Description: Testbench for LED control module (spi_top).
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


module spi_top_tb (

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
    // wire                            o_frame;

    // Inputs: slave
    // cs  - from master
    // sclk- from master
    // mosi- from master

    // Outputs: slave (everything except of miso)
    // wire                            miso;
    wire                            led1;
    wire                            led2;
    wire                            led3;
    wire                            led4;
    wire                            led5;
    wire                            led6;
    wire                            led7;
    wire                            led8;

    // Utils: used to instantiate master i_frame
    reg  [`CMD_BITS-1:0]            mock_master_cmd_bits;
    reg  [`ADDR_BITS-1:0]           mock_master_addr_bits;
    reg  [`PAYLOAD_BITS-1:0]        mock_master_payload_bits;
    // used for slave i_slv_frame
    /*
    reg  [`CMD_BITS-1:0]            mock_slave_cmd_bits;
    reg  [`ADDR_BITS-1:0]           mock_slave_addr_bits;
    reg  [`PAYLOAD_BITS-1:0]        mock_slave_payload_bits;
    */

    spi_master_mock spi_master_uut (
        .sysclk(clk),
        .tx_enb(tx_enb),
        .i_frame(i_frame),
        .miso(),
        .cs(cs),
        .sclk(sclk),
        .mosi(mosi),
        .o_frame(),
        .o_m_shift_reg_debug(),
        .o_m_serial_debug(),
        .o_m_bit_rx_cnt_debug()
    );

    spi_top spi_top_uut (
        .sysclk(clk),
        .sclk(sclk),
        .cs(cs),
        .mosi(mosi),
        .miso(),
        .led1(led1),
        .led2(led2),
        .led3(led3),
        .led4(led4),
        .led5(led5),
        .led6(led6),
        .led7(led7),
        .led8(led8)
    );

    initial begin
        clk = 0;
        forever #(`SLAVE_CLK_NS/2) clk = ~clk;
    end

    integer i;
    initial begin
        $dumpfile("spi_top_tb_waveforms.vcd");
        $dumpvars(0, spi_top_tb.clk,
                     spi_top_tb.sclk,
                     spi_top_tb.cs,
                     spi_top_tb.mosi,
                     spi_top_tb.i_frame,
                     spi_top_tb.led1,
                     spi_top_tb.spi_top_uut.rx_dv,
                     spi_top_tb.spi_top_uut.led_brightness[0],
                     spi_top_tb.spi_top_uut.pwm_gen[0].pwm_inst.o_pwm,
                     spi_top_tb.spi_top_uut.pwm_gen[0].pwm_inst.o_cnt);

        // Initial conditions
        tx_enb     = 1'b0;
        i_frame    = 0;
        #(3 * `SLAVE_CLK_NS);
        /*
        // Test 1: CMD_NOP should not change any LED brightness
        $display("Test 1: Sending CMD_NOP");
        i_frame = {`CMD_NOP, `ADDR_NONE, `PAYLOAD_NONE};
        tx_enb = 1'b1;
        // Wait for transaction completion
        #(`SLAVE_CLK_NS);
        @(posedge cs);
        #(2.5*`SLAVE_CLK_NS);

        for (i  = 0; i < `NUM_LEDS; i = i + 1) begin
            if (spi_top_uut.led_brightness[i] == 7'h0) begin
                $display("PASS: LED %d has still 0 brightness", i);
            end else begin
                $display("FAILS: LED %d has %d brightness", i, spi_top_uut.led_brightness[i]);
            end
        end

        tx_enb = 1'b0;
        #(20 * `SLAVE_CLK_NS);
        */
        // Test 2: CMD_LED_SET for LED0 (addr 0) to 0x40 (64, mid brightness)
        $display("Test 2: Sending CMD_LED_SET for LED0 to 0x40");
        i_frame = {`CMD_LED_SET, 8'h00, 8'h40}; // left shift payload as only 7 first bit have a value
        tx_enb = 1'b1;
        // Wait for transaction completion
        #(`SLAVE_CLK_NS);
        @(posedge cs);
        #(2.5*`SLAVE_CLK_NS);
        if (spi_top_uut.led_brightness[0] == 7'h40) begin
            $display("PASS: LED0 brightness set to 0x%h", spi_top_uut.led_brightness[0]);
        end else begin
            $display("FAIL: LED0 brightness is 0x%h (expected 0x40)", spi_top_uut.led_brightness[0]);
        end

        tx_enb = 1'b0;
        #(20 * `SLAVE_CLK_NS);
        /*
        // Test 3: CMD_LED_SET for LED7 (addr 7) to 0x7F (max 7-bit brightness)
        $display("Test 3: Sending CMD_LED_SET for LED7 to 0x7F");
        i_frame = {`CMD_LED_SET, 8'h07, 8'h7F}; // left shift payload as only 7 first bit have a value
        tx_enb = 1'b1;
        // Wait for transaction completion
        #(`SLAVE_CLK_NS);
        @(posedge cs);
        #(2.5*`SLAVE_CLK_NS);
        if (spi_top_uut.led_brightness[7] == 7'h7F) begin
            $display("PASS: LED7 brightness set to 0x%h", spi_top_uut.led_brightness[7]);
        end else begin
            $display("FAIL: LED7 brightness is 0x%h (expected 0x7F)", spi_top_uut.led_brightness[7]);
        end

        tx_enb = 1'b0;
        #(20 * `SLAVE_CLK_NS);

        // Test 4: CMD_LED_SET with invalid addr (0x10 > 7) - Should not change any LED
        $display("Test 4: Sending CMD_LED_SET with invalid addr 0x10");
        i_frame = {`CMD_LED_SET, `ADDR_NONE, 8'hFF};
        tx_enb = 1'b1;
        // Wait for transaction completion
        #(`SLAVE_CLK_NS);
        @(posedge cs);
        #(2.5*`SLAVE_CLK_NS);
        if (spi_top_uut.led_brightness[0] == 7'h40 && spi_top_uut.led_brightness[7] == 7'h7F) begin
            $display("PASS: Invalid addr did not change existing brightness");
        end else begin
            $display("FAIL: Brightness changed unexpectedly");
        end

        tx_enb = 1'b0;
        #(20 * `SLAVE_CLK_NS);

        // Test 5: CMD_LED_SET for LED3 (addr 3) to 0x00 (off)
        $display("Test 5: Sending CMD_LED_SET for LED3 to 0x00");
        i_frame = {`CMD_LED_SET, 8'h03, 8'h00};
        tx_enb = 1'b1;
        // Wait for transaction completion
        #(`SLAVE_CLK_NS);
        @(posedge cs);
        #(2.5*`SLAVE_CLK_NS);
        if (spi_top_uut.led_brightness[3] == 7'h00) begin
            $display("PASS: LED3 brightness set to 0x%h", spi_top_uut.led_brightness[3]);
        end else begin
            $display("FAIL: LED3 brightness is 0x%h (expected 0x00)", spi_top_uut.led_brightness[3]);
        end
        */
        #(5 * `SLAVE_CLK_NS);
        $finish;

    end

endmodule