module tb_tpgen();

	reg px_clk = 0;
	reg sys_rst = 0;

	wire vsync_o;
	wire hsync_o;
	wire dval_o;
	wire [7:0] rdata_o;
	wire [7:0] gdata_o;
	wire [7:0] bdata_o;

	always #20 px_clk <= ~px_clk;

	initial begin
		sys_rst = 1;
		#10000;
		sys_rst = 0;
	end

	tp_generator inst_dut (
		.px_clk 	(px_clk),
		.sys_rst 	(sys_rst),

		.vsync_o 	(vsync_o),
		.hsync_o 	(hsync_o),
		.dval_o 	(dval_o),
		.rdata_o	(rdata_o),
		.gdata_o	(gdata_o),
		.bdata_o	(bdata_o)
	);

endmodule