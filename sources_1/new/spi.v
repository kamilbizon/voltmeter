`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/25/2019 02:01:40 PM
// Design Name: 
// Module Name: spi
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

module spi #(parameter bits= 16)
(input clk, rst, en, miso, 
output ss, sclk, output reg [bits-1:0] data_rec);

//`include"func.v" //funkcja logarytmująca
//Parametry czasu trwania:
//m -czas jednego bitu (w połowie zbocze opadające sclk)
//d -opóźnienia na początku 
//Parametry obliczane:
//bm-rozmiar licznika czasu
//bdcnt-rozmiar licznika bitów
localparam m = 5, d = 2, bm= $clog2(m), bdcnt= $clog2(bits); 

//kodowanie stanów
localparam idle= 2'b00, progr= 2'b10, start = 2'b11;

/*fsm_encoding= "user"*/
reg[1:0] st, nst;

reg[bits-1:0] shr; //rejestr przesuwny
reg[bm-1:0] cnt; //licznik czasu trwania stanów
reg[bdcnt:0] dcnt; //licznik bitów transmitowanych
reg tmp, tm, cnten;


//rejestr stanu
always @(posedge clk, posedge rst)
    if(rst) st<= idle;
    else st<= nst;

//logika automatu
always @* begin
    nst= idle;
    cnten= 1'b1;
    case(st)
        idle: begin
            cnten= 1'b0;
            nst= en ? start : idle;
        end
        start: nst = (cnt== d) ? progr : start;
        progr: nst = (dcnt== {(bdcnt+1){1'd0}}) ? idle : progr;
    endcase
end

//licznik czasu trwania stanów i poziomów zegara transmisji 
always @(posedge clk, posedge rst)
    if(rst) cnt<= {bm{1'b0}};
    else if(cnten)
        if(cnt== m | dcnt== {(bdcnt+1){1'd0}}) cnt<= {bm{1'b0}};
        else cnt<= cnt+ 1'b1;

//logika sygnałów wyjściowych
assign ss= ((st== start) | (st== progr))?1'b0:1'b1;
assign sclk= ((st== progr) & (cnt< (m/2 + 1)))?1'b0:1'b1;

//generator zezwolenie dla rejestru przesuwnego
always @(posedge clk, posedge rst)
    if(rst)tmp<= 1'b0;
    else tmp<= sclk;

assign spi_en= ~sclk& tmp;

//licznik bitów
always @(posedge clk, posedge rst)
    if(rst) dcnt<= bits;
    else if(spi_en) dcnt<= dcnt-1'b1;
    else if(en& dcnt== {(bdcnt+1){1'd0}}) dcnt<= bits;

//rejestr przesuwny
//assign mosi = shr[bits-1];
always @(posedge clk, posedge rst)
    if(rst) shr<= {bits{1'b0}};
    else if(spi_en) shr <= {shr[bits-2:0],miso};

//generator zezwolenia zapisu na wyjście
always @(posedge clk, posedge rst)
    if(rst) tm<= 1'b0;
    else tm<= ss;

assign en_out= ss& ~tm;

//rejestr wyjściowy
always @(posedge clk, posedge rst)
    if(rst) data_rec <= {bits{1'b0}};
    else if(en_out) data_rec <= shr;
//assign leds = data_rec[11:4];

endmodule
