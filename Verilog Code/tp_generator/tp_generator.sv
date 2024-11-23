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

	localparam HWIDTH	= HACT + HSP + HFP;
	localparam VWIDTH	= VACT + VSP + VFP + VBP;

	logic 			vsync;
	logic 			hsync;
	logic			dv;

	logic			hsync_d;

	logic [15:0] 	hcnt;
	logic [15:0]	line_cnt;

	////////////////////////////////////////
	// Hsync
	////////////////////////////////////////
	always @(posedge px_clk) begin
		if (sys_rst) begin
			hcnt <= 0;
		end
		else if (hcnt < HWIDTH + HSP) begin
			hcnt <= hcnt + 1;
		end
		else begin
			hcnt <= 0;
		end
	end

	always @(posedge px_clk) begin
		if (sys_rst) begin
			hsync <= 0;
		end
		else if (hcnt < HSP) begin
			hsync <= 0;
		end
		else if (hcnt >= HSP && hcnt < HSP + HWIDTH) begin
			hsync <= 1;
		end
		else begin
			hsync <= 0;
		end
	end

	always @(posedge px_clk) begin
		if (sys_rst) begin
			hsync_d <= 0;
		end
		else begin
			hsync_d <= hsync;
		end
	end

	////////////////////////////////////////
	// Data valid
	////////////////////////////////////////
	always @(posedge px_clk) begin
		if (sys_rst) begin
			dv <= 0;
		end
		else if (hcnt > HSP + HBP) begin
			dv <= 1;
		end
		else if (hcnt > HBP + HACT) begin
			dv <= 0;
		end
		else begin
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
		else if (hsync & ~hsync_d) begin
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
		else if (line_cnt == VSP) begin
			vsync <= 1;
		end
		else if (line_cnt == VSP + VACT) begin
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
