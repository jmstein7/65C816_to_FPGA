`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/10/2024 02:39:41 PM
// Design Name: 
// Module Name: clock_div_128
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module clock_div_128(
    input wire clk_12MHz,  // Input clock at 12 MHz
    output reg clk_8MHz    // Output clock at 8 MHz
);

    // Counter variable
    reg [2:0] counter = 0;

    // Clock division factor calculation: 12 MHz / 8 MHz = 1.5
    // Since we cannot have a fractional counter, we toggle the output clock
    // every 1.5 cycles of the input clock on average.
    always @(posedge clk_12MHz) begin
        counter <= counter + 1;
        if (counter >= 1) begin
            clk_8MHz <= ~clk_8MHz;
            counter <= 0;
        end
    end

endmodule
