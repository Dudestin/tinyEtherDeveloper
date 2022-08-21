module RTL_SYNC_FIFO #(
	parameter DATA_WIDTH = 9,
	parameter FIFO_DEPTH_POWER = 16 // 14:16384, 15:32768, 16:65536  
)(
	full_flag ,       // buffer write ready
	empty_flag ,       // buffer read ready
	din,       // read data out

	dout,       // write data in
	wen,       // write enable
	ren,       // read enable
	clk,       // clock
	rst);      // sync reset ( h active )

	localparam integer FIFO_DEPTH =  1 << 16;

	input wire [DATA_WIDTH-1:0] din;
	input wire wen;
	input wire ren;
	input wire clk; 
	input wire rst; 
	output wire full_flag;
	output wire empty_flag;
	output [DATA_WIDTH-1:0] dout;

	// wires & regs
	reg	[FIFO_DEPTH_POWER:0] wr_ad;       // wr address
	reg [FIFO_DEPTH_POWER:0] rd_ad;       // rd address

	reg	 [DATA_WIDTH-1:0] rtl_mem [0:FIFO_DEPTH-1];  // memory array

	// memory wr
	always  @(posedge clk)
	begin
		if (wen & ~full_flag) 
			rtl_mem[wr_ad[FIFO_DEPTH_POWER-1:0]] <= din ;
	end

	// memory rd
	assign dout = rtl_mem[rd_ad[FIFO_DEPTH_POWER-1:0]]; // no latency edition

	// write pointer
	always  @(posedge clk)
	begin
		if (rst)
			wr_ad   <= {(DATA_WIDTH+1){1'b0}} ;
		else if (wen & ~full_flag)  
			wr_ad   <= wr_ad + 1'b1 ;
	end

	// read pointer
	always  @(posedge clk)
	begin
		if (rst) 
			rd_ad   <= {(DATA_WIDTH+1){1'h0}} ;
		else if (ren & ~empty_flag)
			rd_ad   <= rd_ad + 1'b1 ;
	end
	
	// full flag
	assign full_flag = (wr_ad[FIFO_DEPTH_POWER-1:0] == rd_ad[FIFO_DEPTH_POWER-1:0]) 
		&& (wr_ad[FIFO_DEPTH_POWER] != rd_ad[FIFO_DEPTH_POWER]);
	// empty flag
	assign empty_flag =(wr_ad == rd_ad);	
	
endmodule
