`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/25/2019 03:57:07 PM
// Design Name: 
// Module Name: spi_tb
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


module spi_tb(   );

reg clk, rst, en, miso;


spi #(.bits(16)) uut(.clk(clk), .rst(rst),
            .en(en), .miso(miso), 
 .ss(ss), .sclk(sclk), .data_rec(data_rec) );
             
             
initial begin
    clk = 1'b0;
    forever #5 clk=~clk;
end

initial begin
    rst = 1'b0;
    #1 rst = 1'b1;
    #3 rst = 1'b0;
end

initial begin
    en = 1'b0;
    repeat(4) @(posedge clk);
    #5 en = 1'b1;
    @(posedge clk);
    #5 en = 1'b0;
end

initial begin
    miso = 1'b0;
    #1 miso = 1'b1;
    #500 miso = 1'b0;
end

endmodule
