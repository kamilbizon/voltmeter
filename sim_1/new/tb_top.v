`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/18/2019 01:44:55 PM
// Design Name: 
// Module Name: tb_top
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


module tb_top();

reg clk, rst;


oled_top #(.mod_init_delay(100)) uut(.clk(clk), .rst(rst),
             .sclk(sclk), .sdo(sdo), .dc(dc), .res(res), .vdd(vdd), .vbat(vbat));
             
             
initial begin
    clk = 1'b0;
    forever #5 clk=~clk;
end

initial begin
    rst = 1'b0;
    #1 rst = 1'b1;
    #3 rst = 1'b0;
end

endmodule
