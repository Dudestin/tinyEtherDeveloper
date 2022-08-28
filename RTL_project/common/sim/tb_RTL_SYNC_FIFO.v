`timescale 1ns / 1ps

module tb_RTL_SYNC_FIFO();
	reg [7:0] din;
	reg clk;
	reg we;
	reg EOD_in;

	reg re;

	reg rst;
    integer i;
	initial
	begin
        $dumpfile("./vcd/tb_rtl_sync_fifo.vcd");
        $dumpvars(0, rtl_sync_fifo);
		rst  <= 1'b1;
		clk <= 1'b0;
		din  <= 8'b0;
		we   <= 1'b0;
        re   <= 1'b0;
		#1000 rst <= 1'b0;
		#1000 we <= 1'b1;
		#1000 re <= 1'b1;
		#1000 we <= 1'b0;
		#10000
		$finish;
	end

    always @(posedge clk)
    begin
        din <= din + 1'b1;
    end

	always
	begin
		clk <= 1'b0; #10; clk <= 1'b1; #10;
	end
	

	RTL_SYNC_FIFO #(
        .DATA_WIDTH(8),
        .FIFO_DEPTH_POWER(8),
        .AFULL_CNT(200),
        .AEMPTY_CNT(10)
    ) rtl_sync_fifo(
	.rst(rst),
	.din(din), .clk(clk), .wen(we),
	.dout(), .ren(re),
	.empty_flag(), .aempty_flag(aempty_flag),
	.full_flag(full_flag), .afull_flag(afull_flag)
	// my original signal
	);	
endmodule
