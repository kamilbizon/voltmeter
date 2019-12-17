`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/04/2019 01:48:17 PM
// Design Name: 
// Module Name: oled_top
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


module oled_top #(parameter mod_init_delay=100000, vbat_delay = 100, reg [11:0] d1 = 12'd1000, reg [11:0] d4 = 12'd4000)
(input clk, rst, input spi_adc_miso,
 output sclk, sdo, dc, res, vdd, vbat, output adc_ss, adc_sclk,
 output [7:0] leds);

typedef enum {
       Idle,
       Hold,
       Oper,
       Done
} fsmstate_e;       

fsmstate_e current, next;

wire init_done;
wire oper_done;
wire sclk_init;
wire sclk_oper;
wire en_init;
wire en_oper;
wire sdo_init;
wire sdo_oper;
wire dc_oper;


assign en_init = (current == Hold);
assign en_oper = (current == Oper);
assign sdo = (current == Hold) ? sdo_init : sdo_oper;
assign sclk = (current == Hold) ? sclk_init : sclk_oper;
assign dc = (current == Hold) ? 1'b0 : dc_oper;

fsm_init #(.mod_delay(mod_init_delay), .vbat_delay(vbat_delay)) FSM_INIT(.clk(clk), .rst(rst), .en(en_init),
              .fin(init_done), .sclk(sclk_init), .sdin(sdo_init), .vdd(vdd),
              .vbat(vbat), .res(res));

fsm_oper #(.del4s(d4), .del1s(d1)) FSM_OPER(.clk(clk), .rst(rst), .en(en_oper), .spi_adc_miso(spi_adc_miso),
                  .sdo(sdo_oper), .sclk(sclk_oper), .fin(oper_done), .dc(dc_oper), .adc_ss(adc_ss), .adc_sclk(adc_sclk),
                  .leds(leds));



always @(posedge clk, posedge rst)
    if(rst) begin
        current <= Idle;
        end
    else
        current <= next;
        
always @* begin
            next = Idle;
                case(current)
                    Idle: next = Hold;
                    Hold: next = (init_done ? Oper : Hold);
                    Oper: next = (oper_done ? Done : Oper);
                    Done: next = Done;
                endcase
          end

endmodule
