module test_fifo( 
	input wire CLK_IN,
	input wire RST_N,
	output wire [7:0] fifo_dout,
	output fifo_empty,
	output fifo_aempty,
	output fifo_afull
);

	wire fifo_empty;
	wire fifo_aempty;
	wire fifo_afull;

	reg [7:0] counter;
	
	always @(posedge CLK_IN)
		counter <= counter + 4'b1;

	PACKET_FIFO dut_fifo (
		.rst(~RST_N),
		.di(counter), .clkw(CLK_IN), .we(1'b1),
		.do(fifo_dout),.clkr(CLK_IN), .re(1'b1),
		.empty_flag(fifo_empty), .aempty_flag(fifo_aempty),
		.full_flag(), .afull_flag(fifo_afull),
		.EOD_in(), .EOD_out());	
	

endmodule
