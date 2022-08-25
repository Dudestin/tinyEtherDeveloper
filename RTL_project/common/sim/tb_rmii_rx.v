module tb_rmii_tx (
);
	reg clk;
	reg arst_n;
	
	initial
	begin
        $dumpfile("./vcd/tb_rmii_rx.vcd");
        $dumpvars(0, rmii_rx);
		clk <= 1;
		arst_n <= 0;
		#100 
		arst_n <= 1;
		#10000
		$finish;
	end

	always
	begin
		clk <= 1;
		#10;
		clk <= 0;
		#10;
	end

	reg crs_dv, rxd0, rxd1;

	task preamble;
	begin
		rxd0 <= 1'b1; rxd1 <= 1'b0;
		#620  rxd1 <= 1'b1; rxd1 <= 1'b1;
		#20;
	end
	endtask

	integer i;
	initial
	begin
		crs_dv <= 1'b0;
		rxd0 <= 1'b0;
		rxd1 <= 1'b0;
		#1000
		crs_dv <= 1'b1;
		preamble();
		for (i = 0; i < 100; i = i + 1)
		begin
			rxd0 <= ~rxd0; rxd1 <= ~rxd1;
			#20;
		end
		#1
		crs_dv <= 1'b0;
		#21 crs_dv <= 1'b1;
		#20 crs_dv <= 1'b0;
		#20 crs_dv <= 1'b1;
		#20 crs_dv <= 1'b0;
		#20 crs_dv <= 1'b1;
		#20 crs_dv <= 1'b0;
		#20 crs_dv <= 1'b1;
		#20 crs_dv <= 1'b0;
		#20 crs_dv <= 1'b1;
		#20 crs_dv <= 1'b0;
		#20 crs_dv <= 1'b1;
		#20 crs_dv <= 1'b0;
	end

	wire [7:0] rx_fifo_din;
	wire rx_fifo_wren;
	wire rx_fifo_EOD_in;
	RMII_RX rmii_rx ( 
		.arst_n(arst_n),
		.fifo_afull(1'b0),
		.fifo_din(),
		.fifo_wren(),
		// Original FIFO Signal
		.fifo_EOD_in(),
		// RMII signal
		.REF_CLK(clk), .CRS_DV(crs_dv), .RXD0(rxd0), .RXD1(rxd1)
	);
	
endmodule
