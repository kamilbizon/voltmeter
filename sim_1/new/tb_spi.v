`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/28/2019 02:36:52 PM
// Design Name: 
// Module Name: tb_spi
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


module tb_spi();
   localparam bits = 8;
   reg CLK, RST, EN = 1;
   wire SCLK;
   reg [bits-1:0] DATA = 8'b10101010;
   wire  MOSI;
   wire FINISH;
   spi_fsm #(.bits(bits)) uut(.clk(CLK), .rst(RST), .en(EN), .data2trans(DATA), .fin(FINISH), .sclk(SCLK), .mosi(MOSI));// nazwa modulu, nazwa instancji, .nazwa_portu(SYGNAL)
    
    
    
    initial begin
        CLK = 1'b0;
        
        forever #5 CLK=~CLK;
    end
    
    initial begin
        RST = 1'b0;
        #1 RST=1'b1;
        #3 RST=1'b0;
        #250 RST=1'b1;
        #15 RST=1'b0;
    end
    
    initial begin
        EN = 1'b0;
        #40 EN =1'b1;
    end
    
    always @(posedge FINISH) begin 
        EN = 1'b0;
        repeat(4) @(posedge CLK);
        #1 EN = 1'b1;
      end 
endmodule
