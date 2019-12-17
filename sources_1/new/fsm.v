`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
// 
// Create Date: 10/07/2019 03:37:02 PM
// Design Name: 
// Module Name: fsm
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


module fsm_init #(parameter mod_delay=100000, vbat_delay = 100)(
    input clk,
    input rst,
    input en,
    output reg fin,
    output sclk,
    output sdin,
    output reg vdd, vbat, res
    );
    
 typedef enum {
    Idle,
    Decision,
    Power,
    WaitPre,
    Delay,
    Clear,
    Done,
    Spi
 } fsmstate_e;
            
 fsmstate_e current, next;
 
 localparam nb_cmd = 16;
 localparam [8:0] list_cmd[0:nb_cmd-1] = '{9'h100,
                                           9'h0AE,
                                           9'h102,
                                           9'h103,
                                           9'h08D,
                                           9'h014,
                                           9'h0D9,
                                           9'h0F1,
                                           9'h104,
                                           9'h081,
                                           9'h00F,
                                           9'h0A1,
                                           9'h0C8,
                                           9'h0DA,
                                           9'h020,
                                           9'h0AF};
                                           
 reg [8:0] cmd;
 reg [4:0] cmd_counter;
 reg delay_en;
 reg delay_fin;
 reg [6:0] delay_ms;
 reg spi_en;
 reg spi_fin;
 
spi_fsm SPI_COMP(.clk(clk), .rst(rst), .en(spi_en),
     .data2trans(cmd[7:0]), .mosi(sdin), .sclk(sclk), .fin(spi_fin));
     
 delay #(.mbits(7), .mod(mod_delay)) DELAY_COMP(.clk(clk), .rst(rst), .delay_ms(delay_ms),
         .en(delay_en), .finish(delay_fin));
 
 always @(posedge clk, posedge rst)
    if(rst) begin
        current <= Idle;
        end
    else
        current <= next;
        
 always @(posedge clk, posedge rst)
    if(rst)
        cmd <= 9'b0;
    else if ((current == Idle) & en)
        cmd <= list_cmd[cmd_counter];
        
always @(posedge clk, posedge rst)
   if(rst)
       cmd_counter <= 5'b0;
   else if(cmd_counter == nb_cmd)
               cmd_counter <= 4'b0;
   else if(current == Clear)
        cmd_counter <= cmd_counter + 1;        
                
always @(posedge clk, posedge rst)
     if(rst) begin
        vdd <= 1'b1;
        vbat <= 1'b1;
        res <= 1'b1;
     end else case(cmd)
            9'h100: vdd <= 1'b0;
            9'h102: res <= 1'b0;
            9'h103: res <= 1'b1;
            9'h104: vbat <= 1'b0;
     endcase
     
always @(posedge clk, posedge rst)
          if(rst) begin
             delay_ms <= 7'b1;
          end else case(cmd)
             9'h100: delay_ms <= 7'b1;
             9'h102: delay_ms <= 7'b1;
             9'h104: delay_ms <= vbat_delay;    //7'd100;
             default: delay_ms <= 7'b1;
          endcase
             
 always @* begin
    delay_en = 1'b0;
    spi_en = 1'b0;
    next = Idle;
    fin = 1'b0;
        case(current)
            Idle: next = en ? Decision : Idle;
            Decision: next = cmd[8] ? Power : Spi;
            Power: next = WaitPre;
            WaitPre: next = (cmd == 9'h103) ? Clear : Delay;
            Delay: begin
                        delay_en = 1'b1;
                        if(delay_fin)
                            next = Clear;
                        else
                            next = Delay;
                   end
            Clear: next = (cmd_counter < nb_cmd-1) ? Idle : Done;
            Spi: begin
                    spi_en = 1'b1;
                    if(spi_fin)
                        next = Clear;
                    else
                        next = Spi;
                 end
            Done: 
                if(~en)
                    next = Idle;
                else begin
                    next = Done;
                    fin = 1'b1;
               end
        endcase
  end
      
endmodule