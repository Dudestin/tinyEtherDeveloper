module test_fifo( 
	input wire CLK_IN,
	input wire RST_N,
	output wire [7:0] fifo_din,
	output wire [7:0] fifo_dout,
	output wire fifo_empty,
	output wire fifo_aempty,
	output wire fifo_afull,
	output wire fifo_full
);

	reg [7:0] counter;
	
	always @(posedge CLK_IN or negedge RST_N)
		if (~RST_N)
			counter <= 8'hAA;
		else 
			counter <= counter + 1'b1;

	assign fifo_din = counter;

	// check is FWFT ? 
	FRAME_FIFO dut_fifo (
		.rst(~RST_N),
		.di(fifo_din), .clkw(CLK_IN), .we(1'b1),
		.do(fifo_dout),.clkr(CLK_IN), .re(1'b0),
		.empty_flag(fifo_empty), .aempty_flag(fifo_aempty),
		.full_flag(fifo_full), .afull_flag(fifo_afull),
		.EOD_in(), .EOD_out());	
	
	// assign rd_addr = dut_fifo.radr;
	// assign wr_addr = dut_fifo.wadr;

endmodule
