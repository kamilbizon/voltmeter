`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/02/2019 04:36:58 PM
// Design Name: 
// Module Name: BCDgenerator
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


module  BCDgenerator #(parameter bits= 16, num_decads = 4)
(
    input clk, rst, miso, 
    
    input bcd_start,
    output bcd_end,
    output reg [num_decads*8-1:0] BCD_converted_num,
    output ss, sclk,
    output [7:0] leds);

reg [num_decads*8:0] bcd_to_ascii;
wire [num_decads*4-1:0] bcd_output;
wire [bits-1:0] adc_output;

spi #(.bits(bits)) SPI_ADC (.clk(clk), .rst(rst), .en(spi_en), .miso(miso), .ss(ss), .sclk(sclk), .data_rec(adc_output));
Binary_to_BCD #(.INPUT_WIDTH(bits-4), .DECIMAL_DIGITS(num_decads)) BCD (.i_Clock(clk), .i_Binary(adc_output[15:4]), .i_Start(bcd_en), .o_BCD(bcd_output), .o_DV(bcd_finished));


typedef enum {idle, waitForSPI_ADC, waitForBCD_converter, done} state_e; 
state_e st, nst;

assign spi_en = (st == waitForSPI_ADC);
assign bcd_en = (st == waitForBCD_converter);

always @(posedge clk, posedge rst)
	if(rst)
		st <= idle;
	else
		st <= nst;

always @* begin
	nst = idle;
	case(st)
		idle: nst = bcd_start?waitForSPI_ADC:idle;
		waitForSPI_ADC: nst = ss?waitForBCD_converter:waitForSPI_ADC;
		waitForBCD_converter: nst = bcd_finished?done:waitForBCD_converter;
		done: nst = bcd_start?done:idle;
	endcase
end

always @(posedge clk, posedge rst)
	if(rst)
	   bcd_to_ascii <= {4{1'b0}};
	else begin
	   bcd_to_ascii[7:0] <= {4'h03, bcd_output[3:0]};
	   bcd_to_ascii[15:8] <= {4'h03, bcd_output[7:4]};
	   bcd_to_ascii[23:16] <= {4'h03, bcd_output[11:8]};
	   bcd_to_ascii[31:24] <= {4'h03, bcd_output[15:12]};
	end

assign bcd_end = (st == done);
assign BCD_converted_num = bcd_to_ascii;
assign leds = adc_output[11:4];
    
endmodule
