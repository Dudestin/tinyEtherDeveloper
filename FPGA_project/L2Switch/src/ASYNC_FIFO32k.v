// DATA_WIDTH : 8
// FIFO_DEPTH : 2^12

module ASYNC_FIFO32k
#(parameter WA=12,WD=8)
(input  rst         // reset
,input  wclk        // write clock
,input  wen         // write enable
,input[WD-1:0] wdat // write data
,output reg wfull  // write full
,input  rclk        // read clock
,input  ren         // read enable
,output reg[WD-1:0] rdat  // read data
,output reg rempty // read empty
);

reg[WA:0] wadr;

reg[WA:0] radr;

reg[WA:0] wptr,wptr0,wptr1;

reg[WA:0] rptr,rptr0,rptr1;

wire[WA:0] next_wadr,next_wptr;

wire[WA:0] next_radr,next_rptr;

/*********************************************************

* DPM

********************************************************/

bram32k #(.DATA_WIDTH(8)) bram32k_impl
( 
	.doa(), .dia(wdat), .addra(wadr[WA-1:0]), .clka(wclk), .wea(wen), .rsta(rst), 
	.dob(rdat), .dib(8'b0), .addrb(radr[WA-1:0]), .clkb(clkr), .web(1'b0), .rstb(rst)
);

/*********************************************************

* wclk domain

********************************************************/

/* write address */

always @(posedge wclk or posedge rst) begin

	if(rst)

		{wadr,wptr} <= {{(WA+1){1'b0}},{(WA+1){1'b0}}};

	else if(wen)

		{wadr,wptr} <= {next_wadr,next_wptr};

end

assign next_wadr = wadr + (wen & ~wfull);     // binary

assign next_wptr = next_wadr ^ (next_wadr>>1'b1); // gray

/* 2FF-sync of rptr */

always @(posedge wclk or posedge rst) begin

	if(rst)

		{rptr1,rptr0} <= {{(WA+1){1'b0}},{(WA+1){1'b0}}};

	else

		{rptr1,rptr0} <= {rptr0,rptr};

end

/* full flag */

always @(posedge wclk or posedge rst) begin

	if(rst)

		wfull <= 1'b0;

	else if(next_wptr=={~rptr1[WA:WA-1],rptr1[WA-2:0]})

		wfull <= 1'b1;

	else

		wfull <= 1'b0;

end

/*********************************************************

* rclk domain

********************************************************/

/* read address */

always @(posedge rclk or posedge rst) begin

	if(rst)

		{radr,rptr} <= {{(WA+1){1'b0}},{(WA+1){1'b0}}};

	else if(ren)

		{radr,rptr} <= {next_radr,next_rptr};

end

assign next_radr = radr + (ren & ~rempty);    // binary

assign next_rptr = next_radr ^ (next_radr >> 1);  // gray

/* 2FF-sync of wptr */

always @(posedge rclk or posedge rst) begin

	if(rst)

		{wptr1,wptr0} <= {{(WA+1){1'b0}},{(WA+1){1'b0}}};

	else

		{wptr1,wptr0} <= {wptr0,wptr};

end

/* empty flag */

always @(posedge rclk or posedge rst) begin

	if(rst)

		rempty <= 1'b1;

	else if(next_rptr==wptr1)

		rempty <= 1'b1;

	else

		rempty <= 1'b0;

end
endmodule
