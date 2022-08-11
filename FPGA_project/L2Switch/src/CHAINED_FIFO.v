/* Parameterized Chained ASYNC FIFO */

module CHAINED_FIFO #(
	parameter integer BRAM9k_NUM = 1,
	parameter integer BRAM32k_NUM = 1,
	parameter integer DATA_WIDTH = 8,
	parameter TYPE = "SYSCLK_FIRST"
)( 
	sys_clk,
	alt_clk,
	rst,
	din,
	wen,
	dout,
	ren,
	empty,
	full
);

	input wire sys_clk;
	input wire alt_clk;
	input wire rst;
	input wire [DATA_WIDTH-1:0] din;
	input wire wen;
	output wire [DATA_WIDTH-1:0] dout;
	input wire ren;
	output wire empty;
	output wire full;
	
	genvar i;
	generate
	begin
		// impl. async FIFO9k (using BRAM9k)
		if (TYPE == "SYSCLK_LAST")
		begin
			FIFO_BRAM9k #(.DATA_WIDTH(DATA_WIDTH)) 
				first_fifo9k_impl(.rst(rst), .di(din), .clkw(alt_clk), .we(wen), 
							.do(bram32k_din), .clkr(sys_clk),.re(~bram32k_full),
							.empty_flag(~bram32k_we), .full_flag(full));
		end
		else
		begin
			assign bram32k_we = wen;
			assign bram32k_din = din;
			assign bram32k_full = full;
		end

		// impl. BRAM32k and chain them	
		wire [DATA_WIDTH-1:0] bram32k_data_chain [0:BRAM32k_NUM+1];	
		wire bram32k_empty_chain [0:BRAM32k_NUM+1];
		wire bram32k_full_chain  [0:BRAM32k_NUM+1];		
		wire bram32k_we 		= ~bram32k_empty_chain[0];
		wire [DATA_WIDTH-1:0] bram32k_din = bram32k_data_chain[0];		
		wire bram32k_full 		= bram32k_full_chain[1];
		wire bram32k_re 		= ~bram32k_full_chain[BRAM32k_NUM+1];
		wire [DATA_WIDTH-1:0] bram32k_dout = bram32k_data_chain[BRAM32k_NUM];
		wire bram32k_empty		= bram32k_empty_chain[BRAM32k_NUM];
		for (i = 1; i <= BRAM32k_NUM; i = i + 1)
		begin : impl_fifo32k
			FIFO_BRAM32k #(.DATA_WIDTH(DATA_WIDTH))
				inner_fifo32k_impl(.clk(sys_clk), .rst(rst), 
							.din(bram32k_data_chain[i-1]), .wen(~bram32k_empty_chain[i-1]),
							.dout(bram32k_data_chain[i]),  .ren(~bram32k_full_chain[i+1]),
							.empty(bram32k_empty_chain[i]),.full(bram32k_full_chain[i]));
		end

		// impl. sync BRAM9k and chain them		
		wire [DATA_WIDTH-1:0] bram9k_data_chain [0:BRAM9k_NUM+1];	
		wire bram9k_empty_chain [0:BRAM9k_NUM+1];
		wire bram9k_full_chain  [0:BRAM9k_NUM+1];		
		wire bram9k_we 		= ~bram9k_empty_chain[0];
		wire [DATA_WIDTH-1:0] bram9k_din = bram9k_data_chain[0];		
		wire bram9k_full 		= bram9k_full_chain[1];
		wire bram9k_re 		= ~bram9k_full_chain[BRAM9k_NUM+1];
		wire [DATA_WIDTH-1:0] bram9k_dout = bram9k_data_chain[BRAM9k_NUM];
		wire bram9k_empty		= bram9k_empty_chain[BRAM9k_NUM];
		
		assign bram9k_we  = ~bram32k_empty;
		assign bram9k_din = bram32k_dout;
		assign bram32k_re = ~bram9k_full;
		
		for (i = 1; i <= BRAM9k_NUM; i = i + 1)
		begin : impl_fifo9k
			SYNC_FIFO_BRAM9k #(.DATA_WIDTH(DATA_WIDTH))
				inner_fifo9k_impl(.clk(sys_clk), .rst(rst), 
							.di(bram9k_data_chain[i-1]), .we(~bram9k_empty_chain[i-1]),
							.do(bram9k_data_chain[i]),  .re(~bram9k_full_chain[i+1]),
							.empty_flag(bram9k_empty_chain[i]),.full_flag(bram9k_full_chain[i]));
		end

		// impl. async FIFO9k (using BRAM9k)		
		if (TYPE == "SYSCLK_FIRST")
		begin
			FIFO_BRAM9k #(.DATA_WIDTH(DATA_WIDTH))
				last_fifo9k_impl(.rst(rst), .di(bram9k_dout), .clkw(sys_clk), .we(~bram9k_empty), 
							.do(dout), .clkr(alt_clk), .re(ren),
							.empty_flag(empty), .full_flag(bram9k_re));
		end
		else
		begin
			assign bram9k_re = ren;
			assign dout  = bram9k_dout;
			assign empty = bram9k_empty;
		end
	end
	endgenerate
	
endmodule
