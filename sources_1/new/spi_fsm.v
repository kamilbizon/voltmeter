`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/28/2019 01:39:07 PM
// Design Name: 
// Module Name: spi_fsm
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

module spi_fsm #(parameter bits=8)
            (input clk, rst, en, input [bits-1:0] data2trans, output sclk, reg mosi, fin);
//bdcnt-rozmiar licznika bitów
localparam bdcnt = $clog2(bits); 
//kodowanie stanów
typedef enum {idle, send, hold1, done} states_e;
states_e st, nst;

reg [4:0] div;
//licznik dzielnika zegara
reg [bits-1:0] shr;
//rejestr przesuwny
reg [bdcnt:0] dcnt;
//licznik bitów transmitowanych
reg tmp;
wire sh;
wire last_bit;

reg t;


        
//rejestr stanu
always @(posedge clk, posedge rst)
    if(rst) begin
        st <= idle;
        end
    else
        st <= nst;
        

 //logika automatu
assign fin = (st == done);
 
 always @* begin
    nst = idle;
        case(st)
            idle: nst = en ? send : idle;
            send: nst = last_bit ? hold1 : send;
            hold1: nst = done;
            done: 
                nst = en ? done : idle;
        endcase
  end

//generator zegara transmisji (licznik-dzielnik zegara)
assign sclk = ~div[4];
always @(posedge clk, posedge rst)
if(rst)
    div <= 5'b0;
else if(st == send)
        div <= div + 1;
    else
        div <= 1'b0;

//logika sygnałów wyjściowych
always @(posedge clk, posedge rst)
    if(rst)
        mosi <= 1'b0;
    //else if(st ==  idle && en)
      //  mosi <= 1'b1;
    else if(st==send && sh)
        mosi <= shr[bits-1];

//generator zezwolenie dla rejestru przesuwnego
assign sh = t & ~sclk;
always @(posedge clk, posedge rst)
    if(rst)
        t <= 0;
    else
        t <= sclk;

//licznik bitów
assign last_bit = (dcnt == bits);

always @(posedge clk, posedge rst)
    if(rst) 
        dcnt <= {bdcnt+1{1'b0}};
    else if(st==idle && en)
        dcnt <= {bdcnt+1{1'b0}};
    else if(sh && st==send) 
        dcnt <= dcnt +1;

//rejestr przesuwny
always @(posedge clk, posedge rst) 
    if(rst)
        shr <= {bits{1'b0}};
    else if(st ==  idle && en)
        shr <= data2trans;
    else if(st==send && sh) 
        shr <= {shr[bits-2:0], 1'b0};
     

//generator impulsu sterującego (detector zbocza opadającego zegara transmisji)


//rejestr wyjściowy lini danych


//generator sygnał zakończenia



endmodule