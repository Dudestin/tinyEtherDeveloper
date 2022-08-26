// Synchronous FIFO, for Packet FIFO.
// overlay raw IP FIFO (raw_9b_fifo), for extend EOD data.

module PACKET_FIFO #(
	parameter integer AEMPTY_CNT = 1500, // IP MTU
	parameter integer AFULL_CNT = 16000  // ~= 16384 - MTU
)( 
	arst_n,
	di, clk, we,
	do, re,
	empty_flag, aempty_flag,
	full_flag, afull_flag, 
	// my original signal
	EOD_in, EOD_out
);

	input wire [7:0] di;
	input wire clk;
	input wire we,re;
	input wire arst_n;
	
	output wire [7:0] do;
	output wire empty_flag, aempty_flag;
	output wire full_flag, afull_flag;
	// my original signal
	input  wire EOD_in;
	output wire EOD_out;
	
	wire [8:0] raw_di = {di, EOD_in};
	wire [8:0] raw_do;
	assign do = raw_do[8:1];
	assign EOD_out = raw_do[0];

	raw_9b_fifo raw_fifo (
		.rst(~arst_n),
		.di(raw_di), .clk(clk), .we(we),
		.do(raw_do), .re(re),
		.empty_flag(empty_flag), .aempty_flag(aempty_flag),
		.full_flag(full_flag), .afull_flag(afull_flag) 
	);

endmodule
