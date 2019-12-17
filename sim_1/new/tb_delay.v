`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/21/2019 02:19:44 PM
// Design Name: 
// Module Name: tb_delay
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


module tb_delay();

    reg CLK, RST, EN = 1;
    localparam dd=4;
    reg [dd-1:0] DELAY_MS = 1;
    wire FINISH;
    delay #(.mbits(dd), .mod(1000000)) uut(.clk(CLK), .rst(RST), .en(EN), .delay_ms(DELAY_MS), .finish(FINISH));// nazwa modulu, nazwa instancji, .nazwa_portu(SYGNAL)
    
    
    
    initial begin
        CLK = 1'b0;
        
        forever #5 CLK=~CLK;
    end
    
    initial begin
        RST = 1'b0;
        #1 RST=1'b1;
        #3 RST=1'b0;
        #250 RST=1'b1;
        #251 RST=1'b0;
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
