//////////////////////////////////////////////////////////////////////////////////
// Company: ISAE
// Engineer: Szymon Bogus
//
// Create Date: 13/08/2025
// Design Name:
// Module Name: spi_top
// Project Name: simple-spi
// Target Devices: Zybo Z7-20
// Tool Versions:
// Description: Top module, responsible for SPI slave. It's receiving and
//              interpreting commands. It uses PWM to control LEDs brightness level.
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


module spi_top (
    // Inputs
    // Internal FPGA clock
    input                                  sysclk,
    // Inputs provided through PMOD JA
    input  wire                            sclk,
    input  wire                            cs,
    input  wire                            mosi,
    // PMOD JA output
    output wire                            miso,
    // PMOD JE outputs (LEDs)
    output wire                            led1,
    output wire                            led2,
    output wire                            led3,
    output wire                            led4,
    output wire                            led5,
    output wire                            led6,
    output wire                            led7,
    output wire                            led8
);

    reg                            r_rx_dv          = 1'b0;
    reg                            slv_tx_enb       = 1'b1;   // always enabled
    reg [`MASTER_FRAME_WIDTH-1:0]  i_slv_frame      = 0;

    wire [`CMD_BITS-1:0]           curr_cmd;                  // default `CMD_NOP;
    wire [`ADDR_BITS-1:0]          curr_addr;                 // default `ADDR_NONE;
    wire [`PAYLOAD_BITS-1:0]       curr_payload;              // default `PAYLOAD_NONE;
    
    wire                           rx_dv;
    wire                           rd_bypass;
    wire                           rx_addr_dv;

    wire [`PAYLOAD_BITS-1:0]       tx_payload;                // prepared payload for slave transmission

    // Register file for storing LED information
    reg [`PAYLOAD_BITS-2:0] led_brightness [0:`NUM_LEDS-1];  // register file for brightness values
                                                             // LED birghtness level is 7-bit long
    
    integer i;
    initial begin
        for (i = 0; i < `NUM_LEDS; i = i + 1) begin
            led_brightness[i] = 7'b0;  // all LEDs are set to 0% brithgntess
        end
    end
 
    // PWM instantiations (one per LED)
    wire [`NUM_LEDS-1:0] pwm_out;
    assign {led8, led7, led6, led5, led4, led3, led2, led1} = pwm_out;
    // assign debug_led0_pwm = pwm_out[0];

    genvar j;
    generate
        for (j = 0; j < `NUM_LEDS; j = j + 1) begin : pwm_gen
            pwm pwm_inst (
                .sysclk(sysclk),
                .i_enb(1'b1),
                .i_d(led_brightness[j]),
                .o_pwm(pwm_out[j]),
                .o_cnt()
            );
        end
    endgenerate
    
    spi_slave SPI_SLV (
        .sysclk(sysclk),
        .sclk(sclk),
        .cs(cs),
        .mosi(mosi),
        .i_tx_payload(tx_payload),
        .miso(miso),
        .o_cmd(curr_cmd),
        .o_addr(curr_addr),
        .o_payload(curr_payload),
        .rx_dv(rx_dv),
        .rd_bypass(rd_bypass),
        .rx_addr_dv(rx_addr_dv),
        .o_shift_reg_debug(),
        .o_serial_debug(),
        .o_bit_rx_cnt_debug(),
        .o_debug_stage()
    );

    always @(posedge sysclk) begin
        if (rx_dv == 1'b1 || (rd_bypass == 1'b1 && rx_addr_dv == 1'b1)) begin
            case (curr_cmd)
                `CMD_LED_SET  : begin
                    if (curr_addr < `NUM_LEDS) begin
                        led_brightness[curr_addr] <= curr_payload[7:1];
                    end
                end
                `CMD_LED_READ : begin
                    // already handled with tx_payload as a wire
                end
                `CMD_NOP      : begin
                    // Do nothing
                end
            endcase
        end

    end
    
    assign tx_payload = (rd_bypass == 1'b1 
                     && rx_addr_dv == 1'b1  
                     && curr_addr  < `NUM_LEDS) ? led_brightness[curr_addr] : `PAYLOAD_NONE;
    
    /*
    assign led1 = led_brightness[0];
    assign led2 = led_brightness[1];
    assign led3 = led_brightness[2];
    assign led4 = led_brightness[3];
    assign led5 = led_brightness[4];
    assign led6 = led_brightness[5];
    assign led7 = led_brightness[6];
    assign led8 = led_brightness[7];
    */

endmodule