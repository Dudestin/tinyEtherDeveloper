/* SYNC FIFO using BRAM32k*/

module FIFO_BRAM32k #(
	parameter integer DATA_WIDTH = 8
)( 
	clk,
	rst,
	din,
	wen,
	dout,
	ren,
	empty,
	full
);
	input wire clk;
	input wire rst;
	input wire [DATA_WIDTH-1:0] din;
	input wire wen;
	output wire [DATA_WIDTH-1:0] dout;
	input wire ren;
	output wire empty;
	output wire full;
	
	reg [11:0] w_ptr_reg;
	reg [11:0] r_ptr_reg;
	reg empty_reg;
	reg full_reg;	
	
	// address width : 12, data width : 8
	// Port-A : write , Port-B : read
	bram32k #(.DATA_WIDTH(DATA_WIDTH))
			ram_impl (.clka(clk), .addra(w_ptr_reg), .dia(din),  .doa(),     .wea(wen),  .rsta(rst),
					  .clkb(clk), .addrb(r_ptr_reg), .dib(8'b0), .dob(dout), .web(1'b0), .rstb(rst));

	// write pointer
	always @(posedge clk or posedge rst)
	begin
		if (rst)
			w_ptr_reg <= 12'b0;
		else
		begin
			if (wen & ~full_reg)
				w_ptr_reg <= w_ptr_reg + 1'b1;
		end
	end
	
	// read pointer
	always @(posedge clk or posedge rst)
	begin
		if (rst)
			r_ptr_reg <= 12'b0;
		else
		begin
			if (ren & ~empty_reg)
				r_ptr_reg <= r_ptr_reg + 1'b1;
		end
	end
	
	// full flag
	always @(posedge clk or posedge rst)
	begin
		if (rst)
			full_reg <= 1'b0;
		else 
		begin
			if (w_ptr_reg == r_ptr_reg & wen & ~ren)
				full_reg <= 1'b1;
			else if (full_reg == 1'b1 & ren == 1'b1)
				full_reg <= 1'b0;
		end
	end
	
	// empty flag
	always @(posedge clk or posedge rst)
	begin
		if (rst)
			empty_reg <= 1'b1;
		else 
		begin
			if (empty_reg == 1'b1 & ~wen & ren)
				empty_reg <= 1'b1;
			else if (empty_reg == 1'b1 & wen == 1'b1)
				empty_reg <= 1'b0;
		end
	end
	
endmodule