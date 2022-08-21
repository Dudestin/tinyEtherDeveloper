`timescale 1ns / 1ps

module tb_FRAME_FIFO();
	reg [7:0] din;
	reg clkw;
	reg we;
	reg EOD_in;

	reg clkr;
	reg re;

	reg rst;

	initial
	begin
        $dumpfile("./vcd/tb_frame_fifo.vcd");
        $dumpvars(0, frame_fifo);
		rst  <= 1'b1;
		clkw <= 1'b0; clkr <= 1'b0;
		din  <= 8'b0; EOD_in <= 1'b0;
		we   <= 1'b0; re   <= 1'b0;
		#1000 rst <= 1'b0;
		#1000 we <= 1'b1;
		#100000 re <= 1'b1;
		#10000 we <= 1'b0;
		#500000
		$finish;
	end

	always
	begin
		#10 clkw <= 1'b0; #10 clkw <= 1'b1;
	end
	
	always
	begin
		#40 clkr <= 1'b0; #40 clkr <= 1'b1;
	end

	always 
		#20 din <= din + 1'b1;


	FRAME_FIFO frame_fifo(
	.arst_n(~rst),
	.di(din), .clkw(clkw), .we(we),
	.do(), .clkr(clkr), .re(re),
	.empty_flag(), .aempty_flag(),
	.full_flag(), .afull_flag(), 
	// my original signal
	.EOD_in(EOD_in), .EOD_out()
	);	
endmodule
