`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:
// Design Name: 
// Module Name: 
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
module tp_generator (
	input 	px_clk,
	input	sys_rst,

	output	vsync_o,
	output	hsync_o,
	output	dval_o,
	output [7:0] rdata_o,
	output [7:0] gdata_o,
	output [7:0] bdata_o
);

// VGA 640x480 RG888 (bit depth 8)
// Pixel Clock : 25MHz
// Hsync Pulse : 95 Clock
// Hsync Backporch : 47.5 Clock (48 Clock)
// Hactive width : 635 Clock
// Hsync Frontporch : 15 Clock
// Vsync Pulse : 2 line
// Vsync Frontporch : 11 line
// Vsync Backporch : 31 line

	localparam HACT		= 640;
	localparam HSP	 	= 96;
	localparam HFP 		= 16;
	localparam HBP 		= 48;
	localparam VACT		= 480;
	localparam VSP 		= 2;
	localparam VFP		= 11;
	localparam VBP		= 31;

	localparam HWIDTH	= HACT + HSP + HFP + HBP;
	localparam VWIDTH	= VACT + VSP + VFP + VBP;

	logic 			vsync;
	logic			hsync;

	logic 			h_line;
	logic			dv;

	logic			h_line_d;

	logic [15:0] 	h_cnt;
	logic [15:0]	line_cnt;

	////////////////////////////////////////
	// Hsync
	////////////////////////////////////////
	always @(posedge px_clk) begin
		if (sys_rst) begin
			h_cnt <= 0;
		end
		else if (h_cnt < HWIDTH) begin
			h_cnt <= h_cnt + 1;
		end
		else begin
			h_cnt <= 0;
		end
	end

	always @(posedge px_clk) begin
		if (sys_rst) begin
			h_line <= 0;
		end
		else if (h_cnt < HSP) begin
			h_line <= 0;
		end
		else if (h_cnt >= HSP && h_cnt < (HWIDTH)) begin
			h_line <= 1;
		end
		else begin
			h_line <= 0;
		end
	end

	always @(posedge px_clk) begin
		if (sys_rst) begin
			h_line_d <= 0;
		end
		else begin
			h_line_d <= h_line;
		end
	end

	always @(posedge px_clk) begin
		if (sys_rst) begin
			hsync <= 0;
		end
		else if (vsync && ((line_cnt > 1) && (line_cnt < 481))) begin
			hsync <= h_line;
		end
		else begin
			hsync <= 0;
		end
	end

	////////////////////////////////////////
	// Data valid
	////////////////////////////////////////
	always @(posedge px_clk) begin
		if (sys_rst) begin
			dv <= 0;
		end
		else if (h_cnt == HSP + HBP) begin
			dv <= 1;
		end
		else if (h_cnt == HBP + HACT) begin
			dv <= 0;
		end
	end

	////////////////////////////////////////
	// Vsync
	////////////////////////////////////////
	always @(posedge px_clk) begin
		if (sys_rst) begin
			line_cnt <= 0;
		end
		else if (h_line & ~h_line_d) begin
			line_cnt <= line_cnt + 1;
		end
		else if (line_cnt == VWIDTH) begin
			line_cnt <= 0;
		end
	end

	always @(posedge px_clk) begin
		if (sys_rst) begin
			vsync <= 0;
		end
		else if (line_cnt == VSP + 1) begin
			vsync <= 1;
		end
		else if (line_cnt == VSP + VFP + VACT) begin
			vsync <= 0;
		end
	end

	assign vsync_o = vsync;
	assign hsync_o = hsync;
	assign dval_o = dv;
	assign rdata_o = 8'b0;
	assign gdata_o = 8'b0;
	assign bdata_o = 8'b0;

endmodule
