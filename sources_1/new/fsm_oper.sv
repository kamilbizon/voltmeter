`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module fsm_oper #(parameter reg [11:0] del4s = 12'd4000, reg [11:0] del1s = 12'd1000) 
	(input clk, rst, en, input spi_adc_miso,
    output sdo, sclk, fin, output reg dc, output adc_ss, adc_sclk,
    output [7:0] leds);

reg [7:0] current_screen[0:3][0:15];
//`include "screens.vh"

localparam reg [7:0]  clear_screen[0:3][0:15] = '{
        {8'h20, 8'h20, 8'h20, "0",   "1",   "2",   "3",   8'h20,   8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}, 
        {8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}, 
        {8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}, 
        {8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}};

reg [7:0]  my_screen[0:3][0:15] = '{
        {8'h20, 8'h20, 8'h20, "0",   "1",   "2",   "3",   8'h20,   8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}, 
        {8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}, 
        {8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}, 
        {8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}};

reg [1:0] cnt_screen;
reg [2:0] cnt_clm, cnt_page;
reg [4:0] cnt_ind;
reg [11:0] delay_ms;
reg [10:0] addr;
reg [7:0] romout, spi_data_data;
reg spi_en_data, delay_en, page_en;
wire [7:0] spi_data_cmd, spi_data;
typedef enum {idle, waitForBCD, screen, pageInit, page, sendChar, readMem, spi1, spi2, timeDisp, back, done} state_e; 
state_e st, nst;
spi_fsm SPI_COMP(.clk(clk), .rst(rst), .en(spi_en),
	.data2trans(spi_data), .mosi(sdo), .sclk(sclk), .fin(spi_fin));


localparam num_decads = 4;
localparam bits = 16;
wire [num_decads*8-1:0] BCD_converted_num;

BCDgenerator #(.bits(bits), .num_decads(num_decads)) BCD_GEN (.clk(clk), .rst(rst), .miso(spi_adc_miso), .bcd_start(bcd_start),
                                                              .bcd_end(bcd_end), .BCD_converted_num(BCD_converted_num), .ss(adc_ss), .sclk(adc_sclk),
                                                              .leds(leds));
        
assign bcd_start = (st == waitForBCD);
	
assign spi_data = dc?spi_data_data:spi_data_cmd;
assign spi_en = dc?spi_en_data:up_spi_en;

delay #(.mbits(12)) DELAY_COMP(.clk(clk), .rst(rst), .delay_ms(delay_ms),
	.en(delay_en), .finish(delay_fin));

update_page page_row (.clk(clk), .rst(rst), .en(page_en), .spi_fin(spi_fin), .page(cnt_page[1:0]), 
	.dc(page_fin), .spi_en(up_spi_en), .spi_data(spi_data_cmd));

char2pixels CHAR_LIB_COM(.clk(clk), .en(romen), .addr(addr), .data(romout));
assign romen = (st == readMem);
assign fin = (st == done);

always @(posedge clk, posedge rst)
	if(rst)
		st <= idle;
	else
		st <= nst;

always @* begin
	nst = idle;
	case(st)
		idle: nst = en?waitForBCD:idle;
		waitForBCD: nst = bcd_end?screen:waitForBCD;
		screen: nst = page;	//timeDisp;
		pageInit: if(cnt_page == 3'b100) nst = back;
		          else nst = page;
		page: nst = page_fin?sendChar:page;
		sendChar: nst = readMem;
		readMem: nst = spi1;
		spi1: nst = spi2;
		spi2: nst = spi_fin?back:spi2;
		back: if(cnt_page == 3'b100) nst = timeDisp;
			else if(cnt_ind == 5'b10000) nst = pageInit;
			else nst = sendChar;
		timeDisp: if (cnt_screen == 2'b11) nst = done;
		  else nst = delay_fin?screen:timeDisp;
		done: nst = en?done:idle;
	endcase
end

//pixel byte register
always @(posedge clk, posedge rst)
	if(rst)
		spi_data_data <= 8'b0;
	else if(st == readMem)
		spi_data_data <= romout;
		
//ROM address
always @(posedge clk, posedge rst)
	if(rst)
		addr <= 11'b0;
	else if (st == sendChar)
		addr <= {current_screen[cnt_page][cnt_ind], cnt_clm};

//delay register
always @(posedge clk, posedge rst)
	if(rst)
		delay_ms <= 12'b0;
	else if(st == screen)
		case(cnt_screen)
			2'b00: delay_ms <= del4s;
			2'b01: delay_ms <= del1s;
		endcase

//screen register
always @(posedge clk, posedge rst)
	if(rst)
		current_screen <= clear_screen;
	else if(st == screen) begin
	    my_screen[0][3] <= BCD_converted_num[31:24];
	    my_screen[0][4] <= BCD_converted_num[23:16];
	    my_screen[0][5] <= BCD_converted_num[15:8];
	    my_screen[0][6] <= BCD_converted_num[7:0];

		case(cnt_screen)
			2'b00: current_screen <= my_screen;
			2'b01: current_screen <= my_screen; 
			2'b10: current_screen <= my_screen;
		endcase
	end

//screen counter
always @(posedge clk, posedge rst)
	if(rst)
		cnt_screen <= 2'b0;
	else if (st == idle)
		cnt_screen <= 2'b0;
	else if ((st == back) & (cnt_page == 3'b100))
		cnt_screen <= cnt_screen + 1;

//page counter
always @(posedge clk, posedge rst)
	if(rst)
		cnt_page <= 3'b0;
	else if (st == screen | st == idle)
		cnt_page <= 3'b0;
	else if ((st == back) & (cnt_ind == 5'b10000))
	   //if (cnt_page == 3'b100)
	       //cnt_page <= 3'b0;
	     //else 
	       cnt_page <= cnt_page + 1;
	   
            
            
//charcater index counter
always @(posedge clk, posedge rst)
	if(rst)
		cnt_ind <= 5'b0;
	else if (st == screen | st == pageInit | st == idle)
		cnt_ind <= 5'b0;
	else if ((st == back) & (cnt_clm == 3'b111))
	   //if (cnt_ind == 5'b10000)
	       //cnt_ind <= 5'b0;
	    //else
		  cnt_ind <= cnt_ind + 1;

//pixel column counter
always @(posedge clk, posedge rst)
	if(rst)
		cnt_clm <= 3'b0;
	else if (st == idle)
		cnt_clm <= 2'b0;
	else if (st == back)
	   if (cnt_clm == 3'b111)
	       cnt_clm <= 3'b0;
	   else
            cnt_clm <= cnt_clm + 1;

//delay control
always @(posedge clk, posedge rst)
	if(rst) 
		delay_en <= 1'b0;
	else if (st == back & cnt_page == 3'b100) 
		delay_en <= 1'b1;
	else if (st == timeDisp & delay_fin)
		delay_en <= 1'b0;

//spi control combinatorial logic
always @(posedge clk, posedge rst)
	if(rst) 
		spi_en_data <= 1'b0;
	else if(st == spi1)
		spi_en_data <= 1'b1;
	else if (st == spi2 & spi_fin)
		spi_en_data <= 1'b0;
	
//page control combinatorial logic
always @(posedge clk, posedge rst)
	if(rst) begin
		page_en = 1'b0;
		dc = 1'b1;
	end else 
	case(st)
		screen: begin	//
			page_en = 1'b1;
			dc = 1'b0;
		end
		pageInit: if (~cnt_page[2]) begin	//
            page_en = 1'b1;
            dc = 1'b0;
        end
		page: if (page_fin) begin
			page_en = 1'b0;
			dc = 1'b1;
		end
	endcase

endmodule

