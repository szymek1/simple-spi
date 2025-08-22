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
    wire [`BRIGHTNESS_WIDTH-1:0]    o_frame;

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

    // Debug outputs
    /*
    wire [`PAYLOAD_BITS-2:0]        debug_led0_brightness;
    wire                            debug_led0_pwm;
    wire                            rx_dv;
    wire [`CMD_BITS-1:0]            debug_cmd;
    wire [`ADDR_BITS-1:0]           debug_addr;
    wire [`PAYLOAD_BITS-1:0]        debug_payload;
    */
    wire                            rx_dv;

    spi_master_mock spi_master_uut (
        .sysclk(clk),
        .tx_enb(tx_enb),
        .i_frame(i_frame),
        .miso(miso),
        .cs(cs),
        .sclk(sclk),
        .mosi(mosi),
        .o_frame(o_frame),
        .o_m_shift_reg_debug(),
        .o_m_serial_debug(),
        .o_m_bit_rx_cnt_debug(),
        .rx_dv(rx_dv)
    );

    spi_top spi_top_uut (
        .sysclk(clk),
        .sclk(sclk),
        .cs(cs),
        .mosi(mosi),
        .miso(miso),
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
                     spi_top_tb.miso,
                     spi_top_tb.i_frame,
                     spi_top_tb.led1,
                     spi_top_tb.led2,
                     spi_top_tb.led3,
                     spi_top_tb.led4,
                     spi_top_tb.led5,
                     spi_top_tb.led6,
                     spi_top_tb.led7,
                     spi_top_tb.led8,
                     spi_top_tb.o_frame,
                     spi_top_tb.rx_dv);

        // Initial conditions
        tx_enb     = 1'b0;
        i_frame    = 0;
        #(3 * `SLAVE_CLK_NS);

        // Test 1: CMD_NOP should not change any LED brightness
        $display("Test 1: Sending CMD_NOP");
        i_frame = {`CMD_NOP, `ADDR_NONE, `PAYLOAD_NONE};
        tx_enb = 1'b1;

        // Wait for transaction completion
        #(2 * `SLAVE_CLK_NS);
        tx_enb = 1'b0;
        @(posedge cs);
        #(`SLAVE_CLK_NS);
        for (i  = 0; i < `NUM_LEDS; i = i + 1) begin
            if (spi_top_uut.led_brightness[i] == 1'b0) begin
                $display("PASS: LED %d has still 0 brightness", i);
            end else begin
                $display("FAILS: LED %d has %b brightness", i, spi_top_uut.led_brightness[i]);
            end
        end

        #(2 * `MASTER_CLK_NS);

        // Test 2: CMD_LED_SET for LED1 (addr 0) to 40%
        $display("Test 2: Sending CMD_LED_SET for LED0 to 40");
        i_frame = {`CMD_LED_SET, 8'h00, {7'h28, 1'h0}}; // left shift payload as only 7 first bit have a value
        tx_enb = 1'b1;

        // Wait for transaction completion
        #(2 * `SLAVE_CLK_NS);
        tx_enb = 1'b0;
        @(posedge cs);
        #(5 * `SLAVE_CLK_NS);
        if (spi_top_uut.led_brightness[0] == 7'h28) begin
            $display("PASS: LED0 brightness set to 0x%h", spi_top_uut.led_brightness[0]);
        end else begin
            $display("FAIL: LED0 brightness is 0x%h (expected 28)", spi_top_uut.led_brightness[0]);
        end

        #(2 * `MASTER_CLK_NS);
        
        // Test 3: CMD_LED_SET for LED7 (addr 8) to 60%
        $display("Test 3: Sending CMD_LED_SET for LED7 to 60");
        i_frame = {`CMD_LED_SET, 8'h07, {7'h3C, 1'h0}}; // left shift payload as only 7 first bit have a value
        tx_enb = 1'b1;

        // Wait for transaction completion
        #(2 * `SLAVE_CLK_NS);
        tx_enb = 1'b0;
        @(posedge cs);
        #(5 * `SLAVE_CLK_NS);
        if (spi_top_uut.led_brightness[7] == 7'h3C) begin
            $display("PASS: LED8 brightness set to 0x%h", spi_top_uut.led_brightness[7]);
        end else begin
            $display("FAIL: LED8 brightness is 0x%h (expected 3C)", spi_top_uut.led_brightness[7]);
        end

        #(2 * `MASTER_CLK_NS);

        // Test 4: CMD_LED_SET with invalid addr (0x10 > 7) - Should not change any LED
        $display("Test 4: Sending CMD_LED_SET with invalid addr 0x10");
        i_frame = {`CMD_LED_SET, `ADDR_NONE, 8'hFF};
        tx_enb = 1'b1;

        // Wait for transaction completion
        #(2 * `SLAVE_CLK_NS);
        tx_enb = 1'b0;
        @(posedge cs);
        #(5 * `SLAVE_CLK_NS);
        if (spi_top_uut.led_brightness[0] == 7'h28 && spi_top_uut.led_brightness[7] == 7'h3C) begin
            $display("PASS: Invalid addr did not change existing brightness");
        end else begin
            $display("FAIL: Brightness changed unexpectedly");
        end

        #(2 * `MASTER_CLK_NS);

        // Test 5: CMD_LED_SET for LED4 (addr 3) to 0x00 (off)
        $display("Test 5: Sending CMD_LED_SET for LED3 to 0x00");
        i_frame = {`CMD_LED_SET, 8'h03, {7'h0, 1'h0}};
        tx_enb = 1'b1;

        // Wait for transaction completion
        #(2 * `SLAVE_CLK_NS);
        tx_enb = 1'b0;
        @(posedge cs);
        #(5 * `SLAVE_CLK_NS);
        if (spi_top_uut.led_brightness[3] == 7'h0) begin
            $display("PASS: LED4 brightness set to 0x%h", spi_top_uut.led_brightness[3]);
        end else begin
            $display("FAIL: LED4 brightness is 0x%h (expected 0)", spi_top_uut.led_brightness[3]);
        end

        // Test 6: CMD_LED_READ for LED8 (addr 7)
        $display("Test 6: Sending CMD_LED_READ for LED8 and expecting response");
        i_frame = {`CMD_LED_READ, 8'h07, 8'hC}; // payload section irrelevant
        tx_enb = 1'b1;

        // Wait for transaction completion
        #(2 * `SLAVE_CLK_NS);
        tx_enb = 1'b0;
        @(posedge cs);
        #(`SLAVE_CLK_NS);
        if (o_frame == 7'h3C) begin
            $display("PASS: slave reported LED8 value: %h", o_frame);
        end else begin
            $display("FAIL: slave reported LED8 value: %h, expected 3C", o_frame);
        end

        // Test 7: CMD_LED_READ for LED5 (addr 4) to 0%
        $display("Test 7: Sending CMD_LED_READ for LED5 and expecting response");
        i_frame = {`CMD_LED_READ, 8'h04, 8'hC}; // payload section irrelevant
        tx_enb = 1'b1;

        // Wait for transaction completion
        #(2 * `SLAVE_CLK_NS);
        tx_enb = 1'b0;
        @(posedge cs);
        #(`SLAVE_CLK_NS);
        if (o_frame == 7'h0) begin
            $display("PASS: slave reported LED5 value: %h", o_frame);
        end else begin
            $display("FAIL: slave reported LED5 value: %h, expected 0", o_frame);
        end

        // Test 8: CMD_LED_SET for LED5 (addr 4) to 95%
        $display("Test 8: Sending CMD_LED_SET for LED5 to 95");
        i_frame = {`CMD_LED_SET, 8'h04, {7'h5F, 1'h0}}; // payload section irrelevant
        tx_enb = 1'b1;

        // Wait for transaction completion
        #(2 * `SLAVE_CLK_NS);
        tx_enb = 1'b0;
        @(posedge cs);
        #(5 * `SLAVE_CLK_NS);
        if (spi_top_uut.led_brightness[4] == 7'h5F) begin
            $display("PASS: LED5 brightness set to 0x%h", spi_top_uut.led_brightness[4]);
        end else begin
            $display("FAIL: LED5 brightness is 0x%h (expected 5F)", spi_top_uut.led_brightness[4]);
        end

        // Test 9: CMD_LED_READ for LED5 (addr 4)
        $display("Test 9: Sending CMD_LED_READ for LED5 and expecting response");
        i_frame = {`CMD_LED_READ, 8'h04, 8'hC}; // payload section irrelevant
        tx_enb = 1'b1;

        // Wait for transaction completion
        #(2 * `SLAVE_CLK_NS);
        tx_enb = 1'b0;
        @(posedge cs);
        #(`SLAVE_CLK_NS);
        if (o_frame == 7'h5F) begin
            $display("PASS: slave reported LED5 value: %h", o_frame);
        end else begin
            $display("FAIL: slave reported LED5 value: %h, expected 5F", o_frame);
        end
        
        #(5 * `SLAVE_CLK_NS);
        $finish;

    end

endmodule