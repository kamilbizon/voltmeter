`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/04/2019 02:05:44 PM
// Design Name: 
// Module Name: char2pixels
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


module char2pixels(
    input clk,
    input en,
    input [10:0] addr,
    output reg [7:0] data
    );
    
    reg [7:0] memory [1023:0];
    
    initial $readmemh("pixel_SSD1306.dat", memory);
    
    always @(posedge clk)
        if(en)
            data <= memory[addr];
    
endmodule
