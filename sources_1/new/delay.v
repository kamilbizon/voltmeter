`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/21/2019 01:48:13 PM
// Design Name: 
// Module Name: delay
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


module delay #(parameter mbits = 7, mod = 100000) (
    input clk, rst, en,
    input [mbits-1:0] delay_ms,
    output finish);
    
    
 typedef enum {
       Idle,
       Hold,
       Done
    } fsmstate_e;
 
fsmstate_e current, next;

localparam n = $clog2(mod);

reg [mbits-1:0] cnt_ms;
reg [n:0] cnt1ms;
    
    always @(posedge clk, posedge rst)
        if(rst) 
                current <= Idle;
        else
            current <= next;
            
     always@(posedge clk, posedge rst)
        if(rst)
            cnt1ms <= 0;
        else if (current == Hold) begin
            if(cnt1ms != mod-1)
                cnt1ms <= cnt1ms + 1;
            else
                cnt1ms <= 0;
            end
        else cnt1ms <= 0;
            
      always@(posedge clk, posedge rst)
           if(rst)
               cnt_ms <= 0;
           else if (current == Hold) begin
                if (cnt1ms == mod-2)
                    cnt_ms <= cnt_ms + 1;
                end
           else
                cnt_ms <= 0;
               
     assign finish = (current == Done);
     always @* begin
        next = Idle;
            case(current)
                Idle: if(en) next = Hold;
                Hold: if(cnt_ms < delay_ms) next = Hold;
                      else next = Done;
                Done: 
                    if(~en)
                        next = Idle;
            endcase
      end
    
endmodule
