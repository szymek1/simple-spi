//////////////////////////////////////////////////////////////////////////////////
// Company: ISAE
// Engineer: Szymon Bogus
//
// Create Date: 21/07/2025
// Design Name:
// Module Name: pmw
// Project Name: simple-spi
// Target Devices: Zybo Z7-20
// Tool Versions:
// Description: Pulse-Width-Modulation module. It receives the information what
//              should be the level of a selected LED brightness and outputs
//              control PWM signal.
//
// Dependencies: params.vh
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
`include "../include/params.vh"


module pmw (
    input                               sysclk,
    input  wire                         i_enb,
    input  wire [`BRIGHTNESS_WIDTH-1:0] i_d,   // duty cycle
    output reg                          o_pmw,
    output reg  [`BRIGHTNESS_WIDTH-1:0] o_cnt, // pmw register direct access

);

    localparam                  br_min = (2**`BRIGHTNESS_WIDTH - 1) * `LED_MIN_BRIGHTNESS / 100;
    localparam                  br_max = (2**`BRIGHTNESS_WIDTH - 1) * `LED_MAX_BRIGHTNESS / 100;

    reg [`BRIGHTNESS_WIDTH-1:0] r_d;

    always @(posedge sysclk) begin
        if (!enable) begin
            o_cnt <= 2**`BRIGHTNESS_WIDTH - 1;
            o_pmw <= 1'b0;
        end else begin
            // counter will overflow back to 0
            o_cnt <= o_cnt + 1'b1;
            o_pmw <= ((o_cnt + 1'b1) >= r_d) ? 1'b0 : 1'b1;
        end

        if (o_cnt == (2**`BRIGHTNESS_WIDTH - 1)) begin
            if (i_d < `LED_MIN_BRIGHTNESS)      r_d <= br_min;
            else if (i_d < `LED_MIN_BRIGHTNESS) r_d <= br_max;
            else                                r_d <= i_d;
        end

    end

endmodule
