//////////////////////////////////////////////////////////////////////////////////
// Company: ISAE
// Engineer: Szymon Bogus
//
// Create Date: 21/07/2025
// Design Name:
// Module Name: pmw_tb
// Project Name: simple-spi
// Target Devices: Zybo Z7-20
// Tool Versions:
// Description: Pulse-Width-Modulation testbench module.
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


module pwm_tb (

);

    // PWM inputs
    reg                         clk;
    reg                         i_enb;
    reg [`BRIGHTNESS_WIDTH-1:0] i_d;

    // PWM outputs
    wire                         o_pwm;
    wire [`BRIGHTNESS_WIDTH-1:0] o_cnt;

    pwm uut (
        .sysclk(clk),
        .i_enb(i_enb),
        .i_d(i_d),
        .o_pwm(o_pwm),
        .o_cnt(o_cnt)
    );

    initial begin
        clk = 0;
        forever #(`CLK_NS/2) clk = ~clk; 
    end

    initial begin
        $dumpfile("pwm_tb_waveforms.vcd"); // Add waveform dumping
        $dumpvars(0, pwm_tb.clk, 
                     pwm_tb.i_enb,
                     pwm_tb.i_d,
                     pwm_tb.o_pwm,
                     pwm_tb.o_cnt);

        
        // Reset condition
        i_enb = 1'b0;
        i_d   = 0;
        #(`CLK_NS);

        // Test 1: reseting pwm
        if (o_cnt == (2**`BRIGHTNESS_WIDTH - 1)) begin
            $display("Test 1.1: PASS");
        end else begin
            $display("Test 1.1: FAIL- got %d, expected: %d", o_cnt, (2**`BRIGHTNESS_WIDTH - 1));
        end

        if (o_pwm == 1'b0) begin
            $display("Test 1.2: PASS");
        end else begin
            $display("Test 1.2: FAIL- got %b, expected 0", o_pwm);
        end

        // Test 2: duty cycle set to 25%
        i_enb = 1'b1;
        i_d   = 32; // 25% of 127
        #(`CLK_NS * 2**`BRIGHTNESS_WIDTH);
        $display("Test 2: inspect waveforms for o_pmw high for 32 clocks");

        // Test 3: duty cycle set to 0% (should output 0%)
        i_d = 0;
        #(`CLK_NS * 2**`BRIGHTNESS_WIDTH); 
        if (o_pwm == 1'b0) begin
            $display("Test 3: PASS");
        end else begin
            $display("Test 3: FAIL - o_pwm = %b, expected 0", o_pwm);
        end

        // Test 4: duty cycle set to 100% (should output 90%)
        i_d = 127; // 100% duty cycle
        #(`CLK_NS * 2**`BRIGHTNESS_WIDTH);
        $display("Test 4: inspect waveform for o_pwm high for 127 clocks");

        // End simulation
        #(`CLK_NS * 5);
        $display("Simulation complete");
        $finish;

    end

endmodule
