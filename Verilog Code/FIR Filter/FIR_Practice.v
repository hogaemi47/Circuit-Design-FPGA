`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/28 13:43:12
// Design Name: 
// Module Name: FIR_Practice
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


module FIR_Practice(
	input		CLK,
	input		RSTN,
	input	[15:0]	NOISE_SIGNAL,

	output	[15:0]	FILTERED_SIGNAL
    );

   parameter b1 = 16'H04F6;
   parameter b2 = 16'H0A34;
   parameter b3 = 16'H1089;
   parameter b4 = 16'H1496;
   parameter b5 = 16'H160F;

   reg signed [15:0] coeff [0:8];
   reg signed [15:0] org_signal [0:8];
   reg signed [31:0] multipled_signal [0:8];
   reg signed [32:0] summed_signal [0:4];
   reg signed [33:0] summed_signal_1 [0:2];
   reg signed [34:0] summed_signal_2 [0:1];
   reg signed [35:0] summed_signal_3;


   always @(posedge CLK or negedge RSTN)
   begin
	if (!RSTN) begin
		coeff[0] <= b1;
		coeff[1] <= b2;
		coeff[2] <= b3;
		coeff[3] <= b4;
		coeff[4] <= b5;
		coeff[5] <= b4;
		coeff[6] <= b3;
		coeff[7] <= b2;
		coeff[8] <= b1;
	end
   end
 
   integer j;

   always @(posedge CLK or negedge RSTN)
   begin
	if (!RSTN) begin
		org_signal[0] <= 0;
	end
	else begin
		for (j = 0; j < 9; j = j + 1) begin
			if (j == 0) begin
				org_signal[0] <= NOISE_SIGNAL;
			end
			else begin
				org_signal[j] <= org_signal[j - 1];
			end
		end
	end
   end
 
   integer k;

   always @(posedge CLK or negedge RSTN)
   begin
	if (!RSTN) begin
		multipled_signal[0] <= 0;
	end
	else begin
		for (k = 0; k < 9; k = k + 1) begin
			multipled_signal[k] <= org_signal[k] * coeff[k];
		end
	end
   end

   always @(posedge CLK or negedge RSTN)
   begin
	if (!RSTN) begin
		summed_signal[0] <= 0;
	end
	else begin
		summed_signal[0] <= multipled_signal[0] + multipled_signal[1];
		summed_signal[1] <= multipled_signal[2] + multipled_signal[3];
		summed_signal[2] <= multipled_signal[4] + multipled_signal[5];
		summed_signal[3] <= multipled_signal[6] + multipled_signal[7];
		summed_signal[4] <= multipled_signal[8];
	end
   end

   always @(posedge CLK or negedge RSTN)
   begin
	if (!RSTN) begin
		summed_signal_1[0] <= 0;
	end
	else begin
		summed_signal_1[0] <= summed_signal[0] + summed_signal[1];
		summed_signal_1[1] <= summed_signal[2] + summed_signal[3];
		summed_signal_1[2] <= summed_signal[4];
	end
   end

   always @(posedge CLK or negedge RSTN)
   begin
	if (!RSTN) begin
		summed_signal_2[0] <= 0;
	end
	else begin
		summed_signal_2[0] <= summed_signal_1[0] + summed_signal_1[1];
		summed_signal_2[1] <= summed_signal_1[2];
	end
   end

   always @(posedge CLK or negedge RSTN)
   begin
	if (!RSTN) begin
		summed_signal_3 <= 0;
	end
	else begin
		summed_signal_3 <= summed_signal_2[0] + summed_signal_2[1];
	end
   end

   assign FILTERED_SIGNAL = (summed_signal_3[35:14]);

endmodule
