`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/01 13:59:06
// Design Name: 
// Module Name: FIR_Practice_sim
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


module FIR_Practice_sim();

   localparam CORDIC_CLK_PERIOD = 2;
   localparam FIR_CLK_PERIOD = 10;	// Sampling Clock
   localparam signed [15:0] PI_POS = 16'H6488;
   localparam signed [15:0] PI_NEG = 16'H9878;
   localparam PHASE_INC_2MHZ = 200;
   localparam PHASE_INC_30MHZ = 3000;

   reg cordic_clk = 1'b0;
   reg fir_clk = 1'b0;
   reg phase_tvalid = 1'b0;
   reg signed [15:0] phase_2MHz = 0;
   reg signed [15:0] phase_30MHz = 0;

   wire sincos_2MHz_tvalid;
   wire signed [15:0] sin_2MHz, cos_2MHz;
   wire sincos_30MHz_tvalid;
   wire signed [15:0] sin_30MHz, cos_30MHz;

   // ports
   reg RSTN = 0;
   reg signed [15:0] NOISE_SIGNAL = 0;
   wire signed [15:0] FILTERED_SIGNAL;

   cordic_0 cordic_inst_0 (
	   .aclk		( cordic_clk )
	  ,.s_axis_phase_tvalid	( phase_tvalid )
	  ,.s_axis_phase_tdata	( phase_2MHz )
	  ,.m_axis_dout_tvalid	( sincos_2MHz_tvalid )
	  ,.m_axis_dout_tdata	( {sin_2MHz, cos_2MHz} )
	  );

   cordic_0 cordic_inst_1 (
	   .aclk		( cordic_clk )
	  ,.s_axis_phase_tvalid ( phase_tvalid )
	  ,.s_axis_phase_tdata	( phase_30MHz )
	  ,.m_axis_dout_tvalid	( sincos_30MHz_tvalid )
	  ,.m_axis_dout_tdata	( {sin_30MHz, cos_30MHz} )
	  );

   always @(posedge cordic_clk or negedge RSTN)
   begin
	if (!RSTN) begin
		phase_tvalid <= 0;
	end
	else begin
		phase_tvalid <= 1;
	end
   end

   always @(posedge cordic_clk or negedge RSTN)
   begin
	if (!RSTN) begin
		phase_2MHz <= 0;
	end
	else if ((phase_2MHz + PHASE_INC_2MHZ) < PI_POS) begin
		phase_2MHz <= phase_2MHz + PHASE_INC_2MHZ;
	end
	else begin
		phase_2MHz <= PI_NEG + (phase_2MHz + PHASE_INC_2MHZ - PI_POS);
	end
   end

   always @(posedge cordic_clk or negedge RSTN)
   begin
	if (!RSTN) begin
		phase_30MHz <= 0;
	end
	else if ((phase_30MHz + PHASE_INC_30MHZ) <= PI_POS) begin
		phase_30MHz <= phase_30MHz + PHASE_INC_30MHZ;
	end
	else begin
		phase_30MHz <= PI_NEG + (phase_30MHz + PHASE_INC_30MHZ - PI_POS);
	end
   end

   initial begin
	#10;
	RSTN = 1;
   end

   always begin
	cordic_clk = #(CORDIC_CLK_PERIOD / 2) ~cordic_clk;
   end

   always begin
	fir_clk = #(FIR_CLK_PERIOD / 2) ~fir_clk;
   end

   always @(posedge fir_clk or negedge RSTN)
   begin
	if (!RSTN) begin
		NOISE_SIGNAL[0] <= 0;
	end
	else begin
		NOISE_SIGNAL <= (sin_2MHz + sin_30MHz) / 2;
	end
   end

   FIR_Practice fir_inst (
	   .CLK			( fir_clk )
	  ,.RSTN		( RSTN )
	  ,.NOISE_SIGNAL	( NOISE_SIGNAL )
	  ,.FILTERED_SIGNAL	( FILTERED_SIGNAL )
	  );

endmodule
