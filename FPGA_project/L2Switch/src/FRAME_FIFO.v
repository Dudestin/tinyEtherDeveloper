// original ASYNC FIFO
// using BRAM32k x 2, BRAM9k x 1
// |       BRAM9K       (1-bit) | for delimiter (EOD)
// |  BRAM32K + BRAM32K (8-bit) | for data

module FRAME_FIFO
#(parameter WA=13,WD=8, AEMPTY_CNT=1500, AFULL_CNT=6660) // 2^13 = 8192 depth
( 
	rst,
	di, clkw, we,
	do, clkr, re,
	empty_flag, aempty_flag,
	full_flag, afull_flag, 
	// my original signal
	EOD_in, EOD_out
);

	input wire rst;
	input wire [7:0] di;
	input wire clkw, we;
	input wire clkr,re;

	output wire [7:0] do;
	output reg  afull_flag, aempty_flag;
	output reg  full_flag, empty_flag;
	// my original signal
	input  wire EOD_in;
	output wire EOD_out;
	
	reg[WA:0] wadr;
	reg[WA:0] radr;
	
	wire [WD-1:0] rdat_0;
	bram32k #(.DATA_WIDTH(WD)) bram32k_impl_0
	( 
		.doa(),       .dia(di),   .addra(wadr[WA-2:0]), .clka(clkw), .wea(we &~wadr[WA-1]), .rsta(rst), 
		.dob(rdat_0), .dib(8'b0), .addrb(radr[WA-2:0]), .clkb(clkr), .web(1'b0), .rstb(rst)
	);
	
	wire [WD-1:0] rdat_1;
	bram32k #(.DATA_WIDTH(WD)) bram32k_impl_1
	( 
		.doa(),       .dia(di),   .addra(wadr[WA-2:0]), .clka(clkw), .wea(we & wadr[WA-1]), .rsta(rst), 
		.dob(rdat_1), .dib(8'b0), .addrb(radr[WA-2:0]), .clkb(clkr), .web(1'b0), .rstb(rst)
	);
	
	assign do = (~radr[WA-1]) ? rdat_0 : rdat_1;
	
	/* store delimiters */	
	bram9k bram9k_impl ( 
		.doa(), 	   .dia(EOD_in), .addra(wadr[WA-1:0]), .clka(clkw), .wea(we),  .rsta(rst), 
		.dob(EOD_out), .dib(1'b0),   .addrb(radr[WA-1:0]), .clkb(clkr),  .web(1'b0), .rstb(rst)
	);

	/*********************************************************
	* wclk domain
	********************************************************/
	/* write address */

	reg  [WA:0] wadr_gray;
	
	wire [WA:0] wadr_next = wadr + (we & ~full_flag);
	wire [WA:0] wadr_gray_next = wadr_next ^ (wadr_next >> 1'b1);  
	
	always @(posedge clkw or posedge rst)
	begin
		if (rst)
		begin
			wadr      <= {(WA+1){1'b0}};
			wadr_gray <= {(WA+1){1'b0}};
		end
		else
		begin
			wadr      <= wadr_next;      // bin
			wadr_gray <= wadr_gray_next; // gray
		end
	end

	/* 2FF-sync of rptr */
	wire [WA:0] radr_gray_sync;
	vec_sync_2ff #(WA+1) sync_0 (.clk(clkw), .din(radr_gray), .dout(radr_gray_sync));

	/* full flag */	
	wire [WA:0] radr_sync;	
	my_gray2bin #(.WIDTH(WA+1)) gray2bin_impl0 (.din(radr_gray_sync), .dout(radr_sync));
	

	always @(posedge clkw or posedge rst) begin
		if(rst)
			full_flag <= 1'b0;
		else
			full_flag <= wadr_next[WA:0] == {~radr_sync[WA], radr_sync[WA-1:0]};
	end

	
	/* also full flag */
	
	wire [WA:0] diff_adr_w = wadr_next - radr_sync;
	always @(posedge clkw or posedge rst) begin
		if(rst)
			afull_flag <= 1'b1;
		else
			afull_flag <= ~(~diff_adr_w[WA] & (diff_adr_w[WA-1:0] <= AFULL_CNT));
	end

	/*********************************************************
	* rclk domain
	********************************************************/
	/* read address */

	reg  [WA:0] radr_gray;
	
	wire [WA:0] radr_next = radr + (re & ~empty_flag);
	wire [WA:0] radr_gray_next = radr_next ^ (radr_next >> 1'b1);
	
	always @(posedge clkr or posedge rst)
	begin
		if (rst)
		begin
			radr      <= {(WA+1){1'b0}};
			radr_gray <= {(WA+1){1'b0}};
		end
		else
		begin
			radr      <= radr_next;      // bin
			radr_gray <= radr_gray_next; // gray
		end
	end

	/* 2FF-sync of wptr */
	wire [WA:0] wadr_gray_sync;
	vec_sync_2ff #(WA+1) sync_1 (.clk(clkr), .din(wadr_gray), .dout(wadr_gray_sync));

	/* empty flag */
	wire [WA:0] wadr_sync;	
	my_gray2bin #(.WIDTH(WA+1)) gray2bin_impl1 (.din(wadr_gray_sync), .dout(wadr_sync));
	
	always @(posedge clkr or posedge rst) begin
		if(rst)
			empty_flag <= 1'b1;
		else
			empty_flag <= (radr_next == wadr_sync);
	end
	
	/* also empty flag */
	wire [WA:0] diff_adr_r = wadr_sync - radr_next;	

	always @(posedge clkr or posedge rst) begin
		if(rst)
			aempty_flag <= 1'b1;
		else
			aempty_flag <= ~(~diff_adr_r[WA] & (diff_adr_r[WA-1:0] >= AEMPTY_CNT));
	end

endmodule
